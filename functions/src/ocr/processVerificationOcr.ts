import * as admin from "firebase-admin";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {logger} from "firebase-functions";
import {defineString} from "firebase-functions/params";
import {FieldValue} from "firebase-admin/firestore";
import {
  ADMIN_STATUS_PROCESSING,
  buildFailurePayload,
  buildSuccessPayload,
  extractFieldsWithGemini,
  hasDocumentUpload,
  mimeTypeForPath,
  OCR_STATUS_PENDING,
  OCR_STATUS_PROCESSING,
  processWithDocumentAi,
  shouldStartVerificationOcr,
  type VerificationRequestLike,
} from "./verificationOcrPipeline";

const documentAiProcessorName = defineString("DOCUMENT_AI_PROCESSOR_NAME");
const geminiProjectId = defineString("GEMINI_PROJECT_ID", {
  default: process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || "final-year-project-faisal",
});
const geminiLocation = defineString("GEMINI_LOCATION", {
  default: "asia-southeast1",
});

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

      await requestRef.update({
        ...successPayload,
        ocrError: FieldValue.delete(),
        ocrProcessedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      logger.info("Verification OCR completed", {
        requestId,
        fieldsCount: Object.keys(extractedFields).length,
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

function stringValue(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

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
