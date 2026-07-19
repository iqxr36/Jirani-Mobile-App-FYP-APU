// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : processVerificationOcr.ts (TypeScript source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Sunday,28-June-2026
// Last Edited on  : Saturday,18-July-2026

import * as admin from "firebase-admin";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {logger} from "firebase-functions";
import {defineString} from "firebase-functions/params";
import {FieldValue} from "firebase-admin/firestore";
import {
  ADMIN_STATUS_MANUAL_CHECK_REQUIRED,
  ADMIN_STATUS_OCR_MATCHED,
  ADMIN_STATUS_PROCESSING,
  buildFailurePayload,
  buildSuccessPayload,
  evaluateAutoVerification,
  extractFieldsWithGemini,
  hasDocumentUpload,
  mimeTypeForPath,
  OCR_STATUS_PENDING,
  OCR_STATUS_PROCESSING,
  processWithDocumentAi,
  shouldStartVerificationOcr,
  type VerificationRequestLike,
  type VerificationUserLike,
} from "./verificationOcrPipeline";
import {createInAppNotificationIfAbsent} from "../notifications";

const documentAiProcessorName = defineString("DOCUMENT_AI_PROCESSOR_NAME");
const geminiProjectId = defineString("GEMINI_PROJECT_ID", {
  default: process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || "final-year-project-faisal",
});
const geminiLocation = defineString("GEMINI_LOCATION", {
  default: "asia-southeast1",
});

// Verification OCR feature: processes submitted verification documents with Document AI, Gemini extraction, and admin notification.
export const processVerificationRequestOcr = onDocumentWritten(
  {
    document: "verificationRequests/{requestId}",
    region: "asia-southeast1",
    timeoutSeconds: 300,
    memory: "1GiB",
    maxInstances: 5,
  },
  async (event) => {
    const before = event.data?.before.data() as VerificationRequestLike | undefined;
    const after = event.data?.after.data() as VerificationRequestLike | undefined;
    if (!shouldStartVerificationOcr(before, after)) return;

    const requestId = event.params.requestId;
    const db = admin.firestore();
    const requestRef = db.collection("verificationRequests").doc(requestId);

    const claimed = await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(requestRef);
      const current = snapshot.data() as VerificationRequestLike | undefined;
      if (!snapshot.exists || !hasDocumentUpload(current)) return false;

      const currentStatus = stringValue(current?.ocrStatus);
      if (currentStatus !== "" && currentStatus !== OCR_STATUS_PENDING) {
        return false;
      }

      transaction.update(requestRef, {
        ocrStatus: OCR_STATUS_PROCESSING,
        adminStatus: ADMIN_STATUS_PROCESSING,
        ocrError: FieldValue.delete(),
        ocrStartedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return true;
    });

    if (!claimed) {
      logger.info("OCR request was not claimed", {requestId});
      return;
    }

    let extractedText = "";

    try {
      const latest = await requestRef.get();
      const data = latest.data() as VerificationRequestLike | undefined;
      if (!data) throw new Error("Verification request no longer exists.");

      const storagePath = stringValue(data.storagePath);
      const processorName = documentAiProcessorName.value().trim();
      if (!processorName) {
        throw new Error("DOCUMENT_AI_PROCESSOR_NAME is not configured.");
      }

      const storageBucket =
        stringValue(data.storageBucket) ||
        storageBucketFromUrl(stringValue(data.documentUrl)) ||
        storageBucketFromUrl(stringValue(data.fileUrl));
      const bucket = storageBucket ?
        admin.storage().bucket(storageBucket) :
        admin.storage().bucket();
      const file = bucket.file(storagePath);

      logger.info("Resolved verification OCR storage object", {
        requestId,
        storageBucket: bucket.name,
        storagePath,
      });

      const [exists] = await file.exists();
      if (!exists) {
        throw new Error(
          `Uploaded verification document was not found in Storage: ${bucket.name}/${storagePath}.`,
        );
      }

      const [buffer] = await file.download();
      const mimeType = mimeTypeForPath(storagePath);

      logger.info("Processing verification document with Document AI", {
        requestId,
        storagePath,
        mimeType,
      });

      const documentAiResult = await processWithDocumentAi({
        processorName,
        fileBuffer: buffer,
        mimeType,
      });

      extractedText = documentAiResult.text;
      if (!extractedText.trim()) {
        throw new Error("Document AI did not return readable text.");
      }

      logger.info("Extracting verification fields with Gemini", {
        requestId,
        textLength: extractedText.length,
        pageCount: documentAiResult.pageCount,
      });

      const extractedFields = await extractFieldsWithGemini({
        projectId: geminiProjectId.value(),
        location: geminiLocation.value(),
        context: {
          documentType: stringValue(data.documentType),
          fullName: stringValue(data.fullName),
          unitNumber: stringValue(data.unitNumber),
          communityName: stringValue(data.communityName),
          documentText: extractedText,
        },
      });

      const successPayload = buildSuccessPayload({
        ocrText: extractedText,
        pageCount: documentAiResult.pageCount,
        extractedFields,
      });

      const userId = stringValue(data.userId);
      const userRef = userId ? db.collection("users").doc(userId) : null;
      const userSnap = userRef ? await userRef.get() : null;
      const userData = userSnap?.data() as VerificationUserLike | undefined;
      const autoVerification = evaluateAutoVerification({
        request: data,
        user: userData,
        extractedFields,
        ocrText: extractedText,
      });

      if (autoVerification.eligible) {
        await requestRef.update({
          ...successPayload,
          status: stringValue(data.status) || "submitted",
          adminStatus: ADMIN_STATUS_OCR_MATCHED,
          autoVerification,
          verificationMethod: "ocr_recommendation",
          ocrError: FieldValue.delete(),
          ocrProcessedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        await notifyAdminsForOcrResult(db, {
          requestId,
          residentId: userId,
          residentName: stringValue(data.fullName) || residentNameFromUser(userData),
          communityId: stringValue(data.communityId),
          communityName: stringValue(data.communityName),
          decision: "ocr_matched",
          reasons: [],
        });

        logger.info("Verification OCR matched and awaits admin approval", {
          requestId,
          userId,
          reasons: autoVerification.reasons,
        });
      } else {
        await requestRef.update({
          ...successPayload,
          adminStatus: ADMIN_STATUS_MANUAL_CHECK_REQUIRED,
          autoVerification,
          ocrError: FieldValue.delete(),
          ocrProcessedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        await notifyAdminsForOcrResult(db, {
          requestId,
          residentId: userId,
          residentName: stringValue(data.fullName) || residentNameFromUser(userData),
          communityId: stringValue(data.communityId),
          communityName: stringValue(data.communityName),
          decision: "manual_review",
          reasons: autoVerification.reasons,
        });
      }

      logger.info("Verification OCR completed", {
        requestId,
        fieldsCount: Object.keys(extractedFields).length,
        autoVerificationDecision: autoVerification.decision,
      });
    } catch (error) {
      const failurePayload = buildFailurePayload(error, extractedText);
      logger.error("Verification OCR failed", {requestId, error});
      await requestRef.update({
        ...failurePayload,
        ocrProcessedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  },
);

// Verification OCR feature: safely reads trimmed string values from Firestore data.
function stringValue(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

// Verification OCR feature: extracts a Firebase/GCS bucket name from legacy document URLs.
function storageBucketFromUrl(value: string): string {
  if (!value) return "";

  try {
    const url = new URL(value);
    if (url.hostname === "firebasestorage.googleapis.com") {
      const match = url.pathname.match(/^\/v0\/b\/([^/]+)\/o\//);
      return match ? decodeURIComponent(match[1]) : "";
    }

    if (url.hostname.endsWith(".storage.googleapis.com")) {
      return url.hostname.replace(/\.storage\.googleapis\.com$/, "");
    }

    if (url.hostname === "storage.googleapis.com") {
      const match = url.pathname.match(/^\/([^/]+)\//);
      return match ? decodeURIComponent(match[1]) : "";
    }
  } catch {
    return "";
  }

  return "";
}

// Verification OCR feature: builds a resident display name for OCR admin notifications.
function residentNameFromUser(user: VerificationUserLike | undefined): string {
  if (!user) return "Resident";
  const fullName = stringValue(user.fullName);
  if (fullName) return fullName;
  const firstName = stringValue(user.firstName);
  const lastName = stringValue(user.lastName);
  return `${firstName} ${lastName}`.trim() || "Resident";
}

// Verification OCR feature: notifies scoped admins when OCR matched details or requires manual review.
async function notifyAdminsForOcrResult(
  db: admin.firestore.Firestore,
  params: {
    requestId: string;
    residentId: string;
    residentName: string;
    communityId: string;
    communityName: string;
    decision: "ocr_matched" | "manual_review";
    reasons: string[];
  },
): Promise<void> {
  const admins = await db.collection("admins").get();
  const reason = params.reasons[0] || "OCR details need admin confirmation.";
  const matched = params.decision === "ocr_matched";
  const notified = new Set<string>();

  await Promise.all(admins.docs.map(async (doc) => {
    const data = doc.data();
    const uid = stringValue(data.uid) || doc.id;
    if (!uid || notified.has(uid)) return;
    if (data.isActive === false) return;

    const role = stringValue(data.role);
    const adminCommunityId = stringValue(data.communityId);
    const adminCommunityName = stringValue(data.communityName);
    const inScope = role === "systemAdmin" ||
      (params.communityId && adminCommunityId === params.communityId) ||
      (params.communityName && adminCommunityName === params.communityName);
    if (!inScope) return;

    notified.add(uid);
    await createInAppNotificationIfAbsent(
      db,
      `verification_${params.decision}_${params.requestId}_${uid}`,
      {
        userId: uid,
        actorId: "system_ocr",
        type: matched ? "verificationOcrMatched" : "verificationOcrReview",
        title: matched ? "OCR matched resident details" : "Verification needs review",
        body: matched ?
          `${params.residentName}'s submitted information matches the uploaded document. Admin approval is still required.` :
          `${params.residentName}'s document was extracted, but needs admin review. ${reason}`,
        category: "verification",
        verificationRequestId: params.requestId,
        residentId: params.residentId,
        communityId: params.communityId,
        ocrDecision: params.decision,
      },
    );
  }));
}
