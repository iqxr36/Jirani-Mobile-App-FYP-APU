import {v1 as documentai} from "@google-cloud/documentai";
import {ImageAnnotatorClient} from "@google-cloud/vision";
import * as admin from "firebase-admin";
import {FieldValue} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {setGlobalOptions} from "firebase-functions/v2";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onObjectFinalized} from "firebase-functions/v2/storage";

import {type VerificationRequestData} from "./ocr/extractFields";

admin.initializeApp();
setGlobalOptions({maxInstances: 10, region: "asia-southeast1"});

const PROJECT_ID = "final-year-project-faisal";
const LOCATION = "asia-southeast1";
const PROCESSOR_ID = "f68b8fdbbd030f1f";
const PROCESSOR_VERSION_ID = "4028e939da737d74";
const DOCUMENT_AI_ENDPOINT = `${LOCATION}-documentai.googleapis.com`;
const DOCUMENT_AI_PROCESSOR_VERSION =
  `projects/${PROJECT_ID}/locations/${LOCATION}/processors/${PROCESSOR_ID}` +
  `/processorVersions/${PROCESSOR_VERSION_ID}`;
const MANUAL_CHECK_CONFIDENCE_THRESHOLD = 0.75;
const RESIDENT_DOCUMENTS_PREFIX = "resident_documents/";
const DOCUMENT_TYPE_ACCESS_CARD = "accessCard";
const DOCUMENT_TYPE_OTHER_PROOF = "otherProof";
const REQUIRED_FIELD_KEYS = [
  "tenant_name",
  "landlord_name",
  "unit_number",
  "agreement_date",
  "property_address",
] as const;

const documentAiClient = new documentai.DocumentProcessorServiceClient({
  apiEndpoint: DOCUMENT_AI_ENDPOINT,
});
const visionClient = new ImageAnnotatorClient();
const db = admin.firestore();
const storage = admin.storage();

type VerificationRequest = VerificationRequestData & {
  documentUrl?: string;
  storagePath?: string;
};

type RequiredFieldKey = (typeof REQUIRED_FIELD_KEYS)[number];

type ExtractionSource = "document_ai";

type ExtractedField = {
  value: string;
  confidence: number;
  source: ExtractionSource;
};

type ExtractedFields = Partial<Record<RequiredFieldKey, ExtractedField>>;

type ExtractionResult = {
  text: string;
  fields: ExtractedFields;
  provider: "document_ai" | "ocr_fallback";
  documentAiUsed: boolean;
  fallbackUsed: boolean;
};

type DocumentAiDocument = {
  text?: string | null;
  entities?: DocumentAiEntity[] | null;
};

type DocumentAiEntity = {
  type?: string | null;
  mentionText?: string | null;
  confidence?: number | null;
  normalizedValue?: {
    text?: string | null;
  } | null;
  properties?: DocumentAiEntity[] | null;
};

export const processVerificationRequestOcr = onDocumentCreated(
  "verificationRequests/{requestId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const requestId = event.params.requestId;
    const data = snapshot.data() as VerificationRequest;
    const requestRef = db.collection("verificationRequests").doc(requestId);
    const storagePath =
      data.storagePath?.trim() ||
      storagePathFromDownloadUrl(data.documentUrl ?? "");

    if (storagePath.startsWith(RESIDENT_DOCUMENTS_PREFIX)) {
      logger.info("Skipping Firestore extraction; Storage trigger will process it", {
        requestId,
        storagePath,
      });
      return;
    }

    if (!storagePath) {
      await requestRef.update({
        ocrStatus: "failed",
        adminStatus: "manual_check_required",
        ocrError:
          "Missing storagePath and could not derive it from documentUrl.",
        errorMessage:
          "Missing storagePath and could not derive it from documentUrl.",
        ocrProcessedAt: FieldValue.serverTimestamp(),
        processedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    await markProcessing(requestRef, storagePath);

    try {
      await processRequestExtraction({
        requestId,
        requestRef,
        bucketName: storage.bucket().name,
        storagePath,
        requestData: data,
      });
    } catch (error) {
      await markFailed(requestRef, requestId, error);
    }
  },
);

export const processVerificationDocumentExtraction = onObjectFinalized(
  {region: LOCATION},
  async (event) => {
    const object = event.data;
    const storagePath = object.name ?? "";

    if (!storagePath.startsWith(RESIDENT_DOCUMENTS_PREFIX)) {
      logger.info("Ignoring finalized object outside resident document uploads", {
        storagePath,
      });
      return;
    }

    const parsed = parseResidentDocumentPath(storagePath);
    const requestId = object.metadata?.documentId?.trim() || parsed?.documentId;
    const residentId = object.metadata?.residentId?.trim() || parsed?.residentId;

    if (!parsed || !requestId || !residentId) {
      logger.error("Could not parse resident document upload path", {
        storagePath,
      });
      return;
    }

    logger.info("Processing uploaded verification document", {
      requestId,
      residentId,
      storagePath,
    });

    try {
      const requestRef = db.collection("verificationRequests").doc(requestId);
      const snapshot = await requestRef.get();
      if (!snapshot.exists) {
        logger.error("Uploaded document has no verification request", {
          requestId,
          storagePath,
        });
        return;
      }

      const requestData = snapshot.data() as VerificationRequest;
      await markProcessing(requestRef, storagePath);
      await processRequestExtraction({
        requestId,
        requestRef,
        bucketName: object.bucket,
        storagePath,
        requestData,
      });
    } catch (error) {
      const requestRef = db.collection("verificationRequests").doc(requestId);
      await markFailed(requestRef, requestId, error);
    }
  },
);

async function markProcessing(
  requestRef: admin.firestore.DocumentReference,
  storagePath: string,
) {
  await requestRef.update({
    ocrStatus: "processing",
    adminStatus: "processing",
    ocrError: FieldValue.delete(),
    errorMessage: FieldValue.delete(),
    storagePath,
  });
}

async function processRequestExtraction(args: {
  requestId: string;
  requestRef: admin.firestore.DocumentReference;
  bucketName: string;
  storagePath: string;
  requestData: VerificationRequest;
}) {
  const mimeType = mimeTypeForPath(args.storagePath);
  const extraction = await extractDocumentFields({
    bucketName: args.bucketName,
    storagePath: args.storagePath,
    mimeType,
    requestId: args.requestId,
    requestData: args.requestData,
  });

  const trimmedText = extraction.text.trim();
  if (!trimmedText && Object.keys(extraction.fields).length === 0) {
    throw new Error("No readable text or fields were detected in this document.");
  }

  const needsManualCheck = requiresManualCheck(extraction.fields);
  const ocrFields = extractedFieldsToOcrFields(extraction.fields);

  await args.requestRef.update({
    adminStatus: needsManualCheck ? "manual_check_required" : "pending_review",
    extractedFields: extraction.fields,
    extractionProvider: extraction.provider,
    documentAi: {
      processorVersion: DOCUMENT_AI_PROCESSOR_VERSION,
      used: extraction.documentAiUsed,
      fallbackUsed: extraction.fallbackUsed,
    },
    ocrStatus: "completed",
    ocrText: trimmedText,
    ocrFields,
    ocrStructuredData: FieldValue.delete(),
    ocrReviewedAt: FieldValue.delete(),
    ocrReviewedBy: FieldValue.delete(),
    ocrError: FieldValue.delete(),
    errorMessage: FieldValue.delete(),
    ocrProcessedAt: FieldValue.serverTimestamp(),
    processedAt: FieldValue.serverTimestamp(),
  });

  logger.info("Verification document extraction completed", {
    requestId: args.requestId,
    provider: extraction.provider,
    adminStatus: needsManualCheck ? "manual_check_required" : "pending_review",
  });
}

async function markFailed(
  requestRef: admin.firestore.DocumentReference,
  requestId: string,
  error: unknown,
) {
  logger.error("Verification document extraction failed", {requestId, error});
  await requestRef.update({
    ocrStatus: "failed",
    adminStatus: "manual_check_required",
    ocrError: errorMessage(error),
    errorMessage: errorMessage(error),
    ocrProcessedAt: FieldValue.serverTimestamp(),
    processedAt: FieldValue.serverTimestamp(),
  });
}

async function extractDocumentFields(args: {
  bucketName: string;
  storagePath: string;
  mimeType: string;
  requestId: string;
  requestData: VerificationRequestData;
}): Promise<ExtractionResult> {
  try {
    const documentAiResult = await extractWithDocumentAi(args);
    return {
      ...documentAiResult,
      provider: "document_ai",
      documentAiUsed: true,
      fallbackUsed: false,
    };
  } catch (error) {
    if (!shouldUseOcrFallback(args.requestData.documentType)) {
      logger.error("Document AI extraction failed; OCR fallback disabled", {
        requestId: args.requestId,
        documentType: args.requestData.documentType,
        error,
      });
      throw error;
    }

    logger.error("Document AI extraction failed; using OCR fallback", {
      requestId: args.requestId,
      documentType: args.requestData.documentType,
      error,
    });
    const fallback = await extractWithVisionOcr(args);
    return {
      ...fallback,
      provider: "ocr_fallback",
      documentAiUsed: false,
      fallbackUsed: true,
    };
  }
}

function shouldUseOcrFallback(documentType: string | undefined): boolean {
  return documentType === DOCUMENT_TYPE_ACCESS_CARD ||
    documentType === DOCUMENT_TYPE_OTHER_PROOF;
}

async function extractWithDocumentAi(args: {
  bucketName: string;
  storagePath: string;
  mimeType: string;
}): Promise<Omit<ExtractionResult, "provider" | "documentAiUsed" | "fallbackUsed">> {
  const bucket = storage.bucket(args.bucketName);
  const [fileBuffer] = await bucket.file(args.storagePath).download();
  const [result] = await documentAiClient.processDocument({
    name: DOCUMENT_AI_PROCESSOR_VERSION,
    rawDocument: {
      content: fileBuffer.toString("base64"),
      mimeType: args.mimeType,
    },
    skipHumanReview: true,
  });
  const document = result.document as DocumentAiDocument | undefined;
  return {
    text: document?.text ?? "",
    fields: extractDocumentAiFields(document),
  };
}

async function extractWithVisionOcr(args: {
  bucketName: string;
  storagePath: string;
  mimeType: string;
  requestId: string;
}): Promise<Omit<ExtractionResult, "provider" | "documentAiUsed" | "fallbackUsed">> {
  const gcsUri = `gs://${args.bucketName}/${args.storagePath}`;
  const rawText = await extractTextFromGcsFile({
    bucketName: args.bucketName,
    gcsUri,
    mimeType: args.mimeType,
    requestId: args.requestId,
  });
  const text = rawText.trim();
  return {
    text,
    fields: {},
  };
}

async function extractTextFromGcsFile(args: {
  bucketName: string;
  gcsUri: string;
  mimeType: string;
  requestId: string;
}): Promise<string> {
  if (args.mimeType === "application/pdf") {
    return extractPdfText(args.bucketName, args.gcsUri, args.requestId);
  }
  return extractImageText(args.gcsUri);
}

async function extractImageText(gcsUri: string): Promise<string> {
  const [result] = await visionClient.documentTextDetection({
    image: {source: {imageUri: gcsUri}},
  });
  return (
    result.fullTextAnnotation?.text ??
    result.textAnnotations?.[0]?.description ??
    ""
  );
}

async function extractPdfText(
  bucketName: string,
  gcsUri: string,
  requestId: string,
): Promise<string> {
  const outputPrefix = `_ocr_outputs/${requestId}/`;
  const destinationUri = `gs://${bucketName}/${outputPrefix}`;

  const [operation] = await visionClient.asyncBatchAnnotateFiles({
    requests: [
      {
        inputConfig: {
          gcsSource: {uri: gcsUri},
          mimeType: "application/pdf",
        },
        features: [{type: "DOCUMENT_TEXT_DETECTION"}],
        outputConfig: {
          gcsDestination: {uri: destinationUri},
          batchSize: 5,
        },
      },
    ],
  });
  await operation.promise();

  const bucket = storage.bucket(bucketName);
  const [files] = await bucket.getFiles({prefix: outputPrefix});
  const jsonFiles = files.filter((file) => file.name.endsWith(".json"));
  if (jsonFiles.length === 0) {
    throw new Error("Vision did not produce OCR output for this PDF.");
  }

  const parts: string[] = [];
  for (const file of jsonFiles) {
    const [content] = await file.download();
    const parsed = JSON.parse(content.toString("utf8")) as VisionPdfOutput;
    for (const response of parsed.responses ?? []) {
      const pageText =
        response.fullTextAnnotation?.text ??
        response.textAnnotations?.[0]?.description ??
        "";
      if (pageText.trim()) parts.push(pageText.trim());
    }
  }

  await Promise.all(files.map((file) => file.delete().catch(() => undefined)));
  return parts.join("\n\n");
}

function extractDocumentAiFields(document?: DocumentAiDocument): ExtractedFields {
  const fields: ExtractedFields = {};
  for (const entity of document?.entities ?? []) {
    collectDocumentAiEntity(fields, entity);
  }
  return fields;
}

function collectDocumentAiEntity(fields: ExtractedFields, entity: DocumentAiEntity) {
  const key = fieldKeyForDocumentAiType(entity.type ?? "");
  const value =
    entity.normalizedValue?.text?.trim() ||
    entity.mentionText?.trim() ||
    "";
  if (key && value) {
    assignField(fields, key, {
      value,
      confidence: normalizedConfidence(entity.confidence),
      source: "document_ai",
    });
  }

  for (const property of entity.properties ?? []) {
    collectDocumentAiEntity(fields, property);
  }
}

function fieldKeyForDocumentAiType(type: string): RequiredFieldKey | undefined {
  const normalized = normalizeFieldName(type);
  if (!normalized) return undefined;
  if (
    normalized.includes("tenant") ||
    normalized.includes("lessee") ||
    normalized.includes("residentname") ||
    normalized.includes("occupant")
  ) {
    return "tenant_name";
  }
  if (
    normalized.includes("landlord") ||
    normalized.includes("owner") ||
    normalized.includes("lessor")
  ) {
    return "landlord_name";
  }
  if (
    normalized.includes("unit") ||
    normalized.includes("apartment") ||
    normalized.includes("houseno") ||
    normalized.includes("lotno")
  ) {
    return "unit_number";
  }
  if (
    normalized.includes("agreementdate") ||
    normalized.includes("tenancydate") ||
    normalized.includes("commencementdate") ||
    normalized === "date" ||
    normalized.includes("startdate")
  ) {
    return "agreement_date";
  }
  if (
    normalized.includes("address") ||
    normalized.includes("premises") ||
    normalized.includes("property")
  ) {
    return "property_address";
  }
  return undefined;
}

function extractedFieldsToOcrFields(fields: ExtractedFields): Record<string, string> {
  const result: Record<string, string> = {};
  const mappings: Array<[RequiredFieldKey, string]> = [
    ["tenant_name", "Tenant Name"],
    ["landlord_name", "Landlord Name"],
    ["unit_number", "Unit Number"],
    ["agreement_date", "Agreement Date"],
    ["property_address", "Property Address"],
  ];

  for (const [fieldKey, label] of mappings) {
    const value = fields[fieldKey]?.value.trim();
    if (value) result[label] = value;
  }
  return result;
}

function assignField(
  fields: ExtractedFields,
  key: RequiredFieldKey,
  field: ExtractedField,
) {
  const existing = fields[key];
  if (!existing || field.confidence > existing.confidence) {
    fields[key] = field;
  }
}

function requiresManualCheck(fields: ExtractedFields): boolean {
  return REQUIRED_FIELD_KEYS.some((key) => {
    const field = fields[key];
    return !field?.value.trim() ||
      field.confidence < MANUAL_CHECK_CONFIDENCE_THRESHOLD;
  });
}

function normalizedConfidence(value: number | null | undefined): number {
  if (typeof value !== "number" || Number.isNaN(value)) return 0;
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

function normalizeFieldName(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]/g, "");
}

function parseResidentDocumentPath(storagePath: string):
  | {residentId: string; documentId: string; fileName: string}
  | undefined {
  const parts = storagePath.split("/");
  if (parts.length < 4 || parts[0] !== "resident_documents") {
    return undefined;
  }
  return {
    residentId: parts[1],
    documentId: parts[2],
    fileName: parts.slice(3).join("/"),
  };
}

function mimeTypeForPath(storagePath: string): string {
  const lower = storagePath.toLowerCase().split("?")[0];
  if (lower.endsWith(".pdf")) return "application/pdf";
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".webp")) return "image/webp";
  if (lower.endsWith(".heic") || lower.endsWith(".heif")) return "image/heic";
  return "image/jpeg";
}

function storagePathFromDownloadUrl(documentUrl: string): string {
  if (!documentUrl.trim()) return "";
  try {
    const url = new URL(documentUrl);
    const marker = "/o/";
    const markerIndex = url.pathname.indexOf(marker);
    if (markerIndex === -1) return "";

    const encodedPath = url.pathname.substring(markerIndex + marker.length);
    if (!encodedPath) return "";

    return decodeURIComponent(encodedPath);
  } catch {
    return "";
  }
}

function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}

interface VisionPdfOutput {
  responses?: Array<{
    fullTextAnnotation?: {text?: string};
    textAnnotations?: Array<{description?: string}>;
  }>;
}
