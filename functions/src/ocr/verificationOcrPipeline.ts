import {GoogleGenAI} from "@google/genai";
import {v1 as documentai} from "@google-cloud/documentai";

const {DocumentProcessorServiceClient} = documentai;

export const OCR_STATUS_PENDING = "pending";
export const OCR_STATUS_PROCESSING = "processing";
export const OCR_STATUS_COMPLETED = "completed";
export const OCR_STATUS_FAILED = "failed";

export const ADMIN_STATUS_PROCESSING = "processing";
export const ADMIN_STATUS_PENDING_REVIEW = "pending_review";
export const ADMIN_STATUS_MANUAL_CHECK_REQUIRED = "manual_check_required";

export type VerificationDocumentType =
  | "tenancyAgreement"
  | "utilityBill"
  | "accessCard"
  | "otherProof"
  | "unknown";

export type ExtractedFieldSource = "document_ai" | "gemini" | "admin_review";

export interface ExtractedVerificationField {
  value: string;
  confidence: number;
  source: ExtractedFieldSource;
}

export type ExtractedVerificationFields = Record<string, ExtractedVerificationField>;

export interface VerificationRequestLike {
  status?: unknown;
  documentType?: unknown;
  documentUrl?: unknown;
  fileUrl?: unknown;
  storageBucket?: unknown;
  storagePath?: unknown;
  ocrStatus?: unknown;
  fullName?: unknown;
  unitNumber?: unknown;
  communityName?: unknown;
}

export interface DocumentAiResult {
  text: string;
  pageCount: number;
}

export interface GeminiExtractionContext {
  documentType: string;
  fullName: string;
  unitNumber: string;
  communityName: string;
  documentText: string;
}

export interface OcrSuccessPayload {
  ocrStatus: string;
  ocrText: string;
  ocrFields: Record<string, string>;
  extractedFields: ExtractedVerificationFields;
  adminStatus: string;
  ocrError: null;
  documentAiPageCount: number;
}

export interface OcrFailurePayload {
  ocrStatus: string;
  adminStatus: string;
  ocrError: string;
  ocrText?: string;
}

type DocumentAiPage = {
  pageNumber?: number | null;
};

type DocumentAiDocument = {
  text?: string | null;
  pages?: DocumentAiPage[] | null;
};

type GeminiFieldValue = {
  value?: unknown;
  confidence?: unknown;
};

const documentAiClients = new Map<string, InstanceType<typeof DocumentProcessorServiceClient>>();

const fieldKeysByDocumentType: Record<VerificationDocumentType, readonly string[]> = {
  tenancyAgreement: [
    "tenant_name",
    "landlord_name",
    "unit_number",
    "property_address",
    "agreement_date",
  ],
  utilityBill: [
    "account_number",
    "bill_date",
    "bill_holder_name",
    "due_date",
    "service_address",
    "total_amount",
    "utility_issuer_or_provider",
    "utility_type",
  ],
  accessCard: [
    "resident_name",
    "unit_number",
    "property_address",
    "issuer",
    "document_date",
    "card_number",
    "summary",
  ],
  otherProof: [
    "resident_name",
    "unit_number",
    "property_address",
    "issuer",
    "document_date",
    "card_number",
    "summary",
  ],
  unknown: [
    "resident_name",
    "unit_number",
    "property_address",
    "issuer",
    "document_date",
    "card_number",
    "summary",
  ],
};

export function normalizeDocumentType(value: unknown): VerificationDocumentType {
  const normalized = String(value ?? "").trim();
  if (normalized === "tenancyAgreement") return "tenancyAgreement";
  if (normalized === "utilityBill") return "utilityBill";
  if (normalized === "accessCard") return "accessCard";
  if (normalized === "otherProof") return "otherProof";
  return "unknown";
}

export function fieldKeysForDocumentType(value: unknown): readonly string[] {
  return fieldKeysByDocumentType[normalizeDocumentType(value)];
}

export function mimeTypeForPath(storagePath: string): string {
  const lower = storagePath.toLowerCase().split("?")[0];
  if (lower.endsWith(".pdf")) return "application/pdf";
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".webp")) return "image/webp";
  if (lower.endsWith(".heic")) return "image/heic";
  if (lower.endsWith(".heif")) return "image/heif";
  return "image/jpeg";
}

export function hasDocumentUpload(data: VerificationRequestLike | undefined): boolean {
  if (!data) return false;
  return cleanString(data.storagePath).length > 0 &&
    (cleanString(data.documentUrl).length > 0 || cleanString(data.fileUrl).length > 0);
}

export function shouldStartVerificationOcr(
  before: VerificationRequestLike | undefined,
  after: VerificationRequestLike | undefined,
): boolean {
  if (!after || !hasDocumentUpload(after)) return false;

  const status = cleanString(after.status);
  if (status !== "submitted" && status !== "pending") return false;

  const ocrStatus = cleanString(after.ocrStatus);
  if (ocrStatus !== "" && ocrStatus !== OCR_STATUS_PENDING) return false;

  const beforeOcrStatus = cleanString(before?.ocrStatus);
  return beforeOcrStatus !== OCR_STATUS_PROCESSING &&
    beforeOcrStatus !== OCR_STATUS_COMPLETED;
}

export function parseProcessorLocation(processorName: string): string {
  const match = processorName.match(/^projects\/[^/]+\/locations\/([^/]+)\/processors\/[^/]+(?:\/processorVersions\/[^/]+)?$/);
  if (!match?.[1]) {
    throw new Error("DOCUMENT_AI_PROCESSOR_NAME must be a full Document AI processor resource path.");
  }
  return match[1];
}

export function normalizeDocumentAiDocument(document: DocumentAiDocument | undefined): DocumentAiResult {
  const text = document?.text?.trim() ?? "";
  const pageCount = document?.pages?.length ?? 0;
  return {text, pageCount};
}

export async function processWithDocumentAi(params: {
  processorName: string;
  fileBuffer: Buffer;
  mimeType: string;
}): Promise<DocumentAiResult> {
  const location = parseProcessorLocation(params.processorName);
  const endpoint = `${location}-documentai.googleapis.com`;
  let client = documentAiClients.get(endpoint);
  if (!client) {
    client = new DocumentProcessorServiceClient({apiEndpoint: endpoint});
    documentAiClients.set(endpoint, client);
  }

  const [result] = await client.processDocument({
    name: params.processorName,
    rawDocument: {
      content: params.fileBuffer.toString("base64"),
      mimeType: params.mimeType,
    },
  });

  return normalizeDocumentAiDocument(result.document as DocumentAiDocument | undefined);
}

export function buildGeminiPrompt(context: GeminiExtractionContext): string {
  const documentType = normalizeDocumentType(context.documentType);
  const keys = fieldKeysForDocumentType(documentType);
  const typeLabel = documentTypeLabel(documentType);
  const text = truncateForPrompt(context.documentText);

  return [
    `Extract admin review fields from this ${typeLabel}.`,
    "",
    "Return ONLY valid JSON. Do not use markdown or code fences.",
    "Use this exact shape:",
    "{\"fields\":{\"field_key\":{\"value\":\"text or null\",\"confidence\":0.0}}}",
    "",
    `Allowed field keys: ${keys.join(", ")}`,
    "",
    "Resident context from the app:",
    `- Resident full name: ${context.fullName || "unknown"}`,
    `- Submitted unit number: ${context.unitNumber || "unknown"}`,
    `- Submitted community/residence: ${context.communityName || "unknown"}`,
    "",
    "Rules:",
    "- Extract exact text from the OCR result when possible.",
    "- Do not invent values that are not present.",
    "- Use null when a field is missing or unclear.",
    "- Confidence must be between 0 and 1.",
    "- For unit_number, prefer the unit written in the document.",
    "- For summary, provide one concise sentence describing the document.",
    "",
    "Document AI OCR text:",
    text,
  ].join("\n");
}

export async function extractFieldsWithGemini(params: {
  projectId: string;
  location: string;
  context: GeminiExtractionContext;
}): Promise<ExtractedVerificationFields> {
  if (!params.projectId.trim()) {
    throw new Error("GEMINI_PROJECT_ID is not configured.");
  }
  if (!params.location.trim()) {
    throw new Error("GEMINI_LOCATION is not configured.");
  }

  const ai = new GoogleGenAI({
    enterprise: true,
    project: params.projectId.trim(),
    location: params.location.trim(),
    apiVersion: "v1",
  });
  const response = await ai.models.generateContent({
    model: "gemini-2.5-flash",
    contents: buildGeminiPrompt(params.context),
    config: {
      systemInstruction:
        "You extract residency verification fields from OCR text for an admin review tool.",
      temperature: 0,
      responseMimeType: "application/json",
    },
  });

  const outputText = String(response.text ?? "").trim();
  if (!outputText) {
    throw new Error("Gemini returned an empty extraction response.");
  }

  return parseGeminiExtraction(outputText, params.context.documentType);
}

export function parseGeminiExtraction(
  rawOutput: string,
  documentType: unknown,
): ExtractedVerificationFields {
  const parsed = parseJsonObject(rawOutput);
  const fieldContainer = isPlainObject(parsed.fields) ? parsed.fields : parsed;
  const keys = fieldKeysForDocumentType(documentType);
  const fields: ExtractedVerificationFields = {};

  for (const key of keys) {
    const normalized = normalizeGeminiField(fieldContainer[key]);
    if (!normalized) continue;
    fields[key] = {
      ...normalized,
      source: "gemini",
    };
  }

  return fields;
}

export function buildSuccessPayload(params: {
  ocrText: string;
  pageCount: number;
  extractedFields: ExtractedVerificationFields;
}): OcrSuccessPayload {
  const ocrFields = extractedFieldsToFieldMap(params.extractedFields);
  return {
    ocrStatus: OCR_STATUS_COMPLETED,
    ocrText: params.ocrText,
    ocrFields,
    extractedFields: params.extractedFields,
    adminStatus: Object.keys(ocrFields).length === 0 ?
      ADMIN_STATUS_MANUAL_CHECK_REQUIRED :
      ADMIN_STATUS_PENDING_REVIEW,
    ocrError: null,
    documentAiPageCount: params.pageCount,
  };
}

export function buildFailurePayload(error: unknown, ocrText?: string): OcrFailurePayload {
  const message = readableErrorMessage(error);
  return {
    ocrStatus: OCR_STATUS_FAILED,
    adminStatus: ADMIN_STATUS_MANUAL_CHECK_REQUIRED,
    ocrError: message,
    ...(ocrText?.trim() ? {ocrText} : {}),
  };
}

export function readableErrorMessage(error: unknown): string {
  if (error instanceof Error && error.message.trim()) {
    return error.message.trim();
  }

  if (isPlainObject(error)) {
    const errorObject = isPlainObject(error.error) ? error.error : error;
    const message = errorObject.message;
    if (typeof message === "string" && message.trim()) {
      return message.trim();
    }

    const status = errorObject.status ?? errorObject.code;
    if (typeof status === "string" && status.trim()) {
      return `API request failed: ${status.trim()}`;
    }
    if (typeof status === "number") {
      return `API request failed with status ${status}.`;
    }
  }

  if (typeof error === "string" && error.trim()) {
    return error.trim();
  }

  return "Unknown OCR error";
}

export function extractedFieldsToFieldMap(
  fields: ExtractedVerificationFields,
): Record<string, string> {
  const result: Record<string, string> = {};
  for (const [key, field] of Object.entries(fields)) {
    const value = field.value.trim();
    if (value) result[key] = value;
  }
  return result;
}

function parseJsonObject(rawOutput: string): Record<string, unknown> {
  const cleaned = rawOutput
    .replace(/```(?:json)?\s*([\s\S]*?)```/g, "$1")
    .trim();
  const firstBrace = cleaned.indexOf("{");
  const lastBrace = cleaned.lastIndexOf("}");
  if (firstBrace === -1 || lastBrace === -1 || lastBrace <= firstBrace) {
    throw new Error("Gemini response did not contain a JSON object.");
  }

  const jsonText = cleaned.slice(firstBrace, lastBrace + 1);
  const parsed = JSON.parse(jsonText) as unknown;
  if (!isPlainObject(parsed)) {
    throw new Error("Gemini response JSON was not an object.");
  }
  return parsed;
}

function normalizeGeminiField(value: unknown): Omit<ExtractedVerificationField, "source"> | null {
  if (typeof value === "string") {
    const trimmed = value.trim();
    return trimmed ? {value: trimmed, confidence: 0.85} : null;
  }

  if (!isPlainObject(value)) return null;
  const field = value as GeminiFieldValue;
  if (field.value === null || field.value === undefined) return null;

  const stringValue = String(field.value).trim();
  if (!stringValue) return null;

  return {
    value: stringValue,
    confidence: clampConfidence(field.confidence),
  };
}

function clampConfidence(value: unknown): number {
  if (typeof value !== "number" || Number.isNaN(value)) return 0.85;
  return Math.min(1, Math.max(0, value));
}

function documentTypeLabel(documentType: VerificationDocumentType): string {
  switch (documentType) {
  case "tenancyAgreement":
    return "tenancy agreement";
  case "utilityBill":
    return "utility bill";
  case "accessCard":
    return "access card";
  case "otherProof":
    return "supporting proof document";
  case "unknown":
    return "residency verification document";
  }
}

function truncateForPrompt(value: string): string {
  const clean = value.trim();
  const maxChars = 60000;
  if (clean.length <= maxChars) return clean;
  return `${clean.slice(0, maxChars)}\n\n[Document text truncated after ${maxChars} characters]`;
}

function cleanString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
