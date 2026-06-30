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
export const ADMIN_STATUS_CONFIRMED = "confirmed";
export const ADMIN_STATUS_OCR_MATCHED = "ocr_matched";

// Verification OCR feature: supported proof document categories used by extraction and admin review.
export type VerificationDocumentType =
  | "tenancyAgreement"
  | "utilityBill"
  | "accessCard"
  | "otherProof"
  | "unknown";

// Verification OCR feature: records whether a field came from AI extraction or admin correction.
export type ExtractedFieldSource = "document_ai" | "gemini" | "admin_review";

// Verification OCR feature: stores one extracted field value, confidence, and source for admin review.
export interface ExtractedVerificationField {
  value: string;
  confidence: number;
  source: ExtractedFieldSource;
}

export type ExtractedVerificationFields = Record<string, ExtractedVerificationField>;

// Verification OCR feature: minimal verificationRequests document shape needed by backend OCR logic.
export interface VerificationRequestLike {
  userId?: unknown;
  status?: unknown;
  documentType?: unknown;
  documentUrl?: unknown;
  fileUrl?: unknown;
  storageBucket?: unknown;
  storagePath?: unknown;
  ocrStatus?: unknown;
  fullName?: unknown;
  unitNumber?: unknown;
  communityId?: unknown;
  communityName?: unknown;
}

// Verification OCR feature: minimal users/{uid} shape used to compare OCR output against resident profile data.
export interface VerificationUserLike {
  firstName?: unknown;
  lastName?: unknown;
  fullName?: unknown;
  email?: unknown;
  phoneNumber?: unknown;
  unitNumber?: unknown;
  communityName?: unknown;
  verificationStatus?: unknown;
}

// Verification OCR feature: normalized text/page result returned by Document AI.
export interface DocumentAiResult {
  text: string;
  pageCount: number;
}

// Verification OCR feature: context passed to Gemini so it extracts fields for the expected resident/document.
export interface GeminiExtractionContext {
  documentType: string;
  fullName: string;
  unitNumber: string;
  communityName: string;
  documentText: string;
}

// Verification OCR feature: Firestore fields written after OCR and field extraction succeed.
export interface OcrSuccessPayload {
  ocrStatus: string;
  ocrText: string;
  ocrFields: Record<string, string>;
  extractedFields: ExtractedVerificationFields;
  adminStatus: string;
  ocrError: null;
  documentAiPageCount: number;
}

// Verification OCR feature: one pass/fail/warning check used in automatic verification recommendation.
export interface AutoVerificationCheck {
  passed: boolean;
  expected?: string;
  actual?: string;
  source?: string;
  skipped?: boolean;
}

// Verification OCR feature: summary decision explaining whether admin can trust the OCR match.
export interface AutoVerificationDecision {
  eligible: boolean;
  decision: "auto_verified" | "manual_review";
  reasons: string[];
  checks: Record<string, AutoVerificationCheck>;
}

// Verification OCR feature: Firestore fields written when OCR or Gemini extraction fails.
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

// Verification OCR feature: normalizes incoming document type strings for extraction logic.
export function normalizeDocumentType(value: unknown): VerificationDocumentType {
  const normalized = String(value ?? "").trim();
  if (normalized === "tenancyAgreement") return "tenancyAgreement";
  if (normalized === "utilityBill") return "utilityBill";
  if (normalized === "accessCard") return "accessCard";
  if (normalized === "otherProof") return "otherProof";
  return "unknown";
}

// Verification OCR feature: returns the expected extraction field keys for the uploaded proof type.
export function fieldKeysForDocumentType(value: unknown): readonly string[] {
  return fieldKeysByDocumentType[normalizeDocumentType(value)];
}

// Verification OCR feature: maps a Storage object path to the MIME type Document AI expects.
export function mimeTypeForPath(storagePath: string): string {
  const lower = storagePath.toLowerCase().split("?")[0];
  if (lower.endsWith(".pdf")) return "application/pdf";
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".webp")) return "image/webp";
  if (lower.endsWith(".heic")) return "image/heic";
  if (lower.endsWith(".heif")) return "image/heif";
  return "image/jpeg";
}

// Verification OCR feature: checks whether a verification request has enough Storage info to process.
export function hasDocumentUpload(data: VerificationRequestLike | undefined): boolean {
  if (!data) return false;
  return cleanString(data.storagePath).length > 0 &&
    (cleanString(data.documentUrl).length > 0 || cleanString(data.fileUrl).length > 0);
}

// Verification OCR feature: decides whether a verification request write should start OCR processing.
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

// Verification OCR feature: extracts the Google Cloud region from a Document AI processor resource name.
export function parseProcessorLocation(processorName: string): string {
  const match = processorName.match(/^projects\/[^/]+\/locations\/([^/]+)\/processors\/[^/]+(?:\/processorVersions\/[^/]+)?$/);
  if (!match?.[1]) {
    throw new Error("DOCUMENT_AI_PROCESSOR_NAME must be a full Document AI processor resource path.");
  }
  return match[1];
}

// Verification OCR feature: converts raw Document AI response into text and page count.
export function normalizeDocumentAiDocument(document: DocumentAiDocument | undefined): DocumentAiResult {
  const text = document?.text?.trim() ?? "";
  const pageCount = document?.pages?.length ?? 0;
  return {text, pageCount};
}

// Verification OCR feature: sends the uploaded proof file to Document AI for OCR text extraction.
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

// Verification OCR feature: builds the structured Gemini prompt for extracting proof fields from OCR text.
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

// Verification OCR feature: calls Gemini and parses extracted fields into normalized confidence records.
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

// Verification OCR feature: parses Gemini JSON output and filters it to expected document fields.
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

// Verification OCR feature: builds Firestore success fields after OCR and Gemini extraction complete.
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

// Verification OCR feature: compares OCR extracted fields with resident/request data to recommend admin action.
export function evaluateAutoVerification(params: {
  request: VerificationRequestLike;
  user: VerificationUserLike | undefined;
  extractedFields: ExtractedVerificationFields;
  ocrText: string;
}): AutoVerificationDecision {
  const reasons: string[] = [];
  const checks: Record<string, AutoVerificationCheck> = {};
  const documentType = normalizeDocumentType(params.request.documentType);

  if (!params.user) {
    return {
      eligible: false,
      decision: "manual_review",
      reasons: ["Resident profile was not found."],
      checks,
    };
  }

  const firstName = cleanString(params.user.firstName);
  const lastName = cleanString(params.user.lastName);
  const fallbackFullName = cleanString(params.user.fullName) ||
    cleanString(params.request.fullName);
  const parsedFallback = splitFallbackName(fallbackFullName);
  const expectedFirstName = firstName || parsedFallback.firstName;
  const expectedLastName = lastName || parsedFallback.lastName;

  const nameField = preferredNameField(documentType, params.extractedFields);
  const nameValue = nameField?.field.value ?? "";
  const normalizedName = normalizeTextForMatch(nameValue);
  const firstNameMatch = nameContainsToken(normalizedName, expectedFirstName);
  const lastNameMatch = nameContainsToken(normalizedName, expectedLastName);
  const nameConfidenceOk = (nameField?.field.confidence ?? 0) >= 0.8;

  checks.firstNameMatch = {
    passed: firstNameMatch,
    expected: expectedFirstName,
    actual: nameValue,
    source: nameField?.key,
  };
  checks.lastNameMatch = {
    passed: lastNameMatch,
    expected: expectedLastName,
    actual: nameValue,
    source: nameField?.key,
  };
  checks.nameConfidence = {
    passed: nameConfidenceOk,
    expected: ">= 0.8",
    actual: String(nameField?.field.confidence ?? 0),
    source: nameField?.key,
  };

  if (!expectedFirstName) reasons.push("Resident first name is missing.");
  if (!expectedLastName) reasons.push("Resident last name is missing.");
  if (!nameValue) reasons.push("Document holder name was not extracted.");
  if (expectedFirstName && !firstNameMatch) {
    reasons.push("Extracted document name does not contain the resident first name.");
  }
  if (expectedLastName && !lastNameMatch) {
    reasons.push("Extracted document name does not contain the resident last name.");
  }
  if (nameField && !nameConfidenceOk) {
    reasons.push("Extracted document name confidence is below 80%.");
  }

  const expectedUnit = cleanString(params.user.unitNumber) ||
    cleanString(params.request.unitNumber);
  const unitMatch = extractedUnitMatches(
    expectedUnit,
    documentType,
    params.extractedFields,
  );
  checks.unitMatch = unitMatch.check;
  if (!expectedUnit) {
    reasons.push("Resident unit number is missing.");
  } else if (!unitMatch.check.passed) {
    reasons.push("Extracted document unit/address does not match the resident unit.");
  }

  checks.emailObserved = emailObservedCheck(
    cleanString(params.user.email),
    params.ocrText,
  );
  checks.phoneObserved = phoneObservedCheck(
    cleanString(params.user.phoneNumber),
    params.ocrText,
  );
  checks.communityObserved = communityObservedCheck(
    cleanString(params.user.communityName) ||
      cleanString(params.request.communityName),
    params.extractedFields,
    params.ocrText,
  );

  const eligible = reasons.length === 0 &&
    firstNameMatch &&
    lastNameMatch &&
    nameConfidenceOk &&
    unitMatch.check.passed;

  return {
    eligible,
    decision: eligible ? "auto_verified" : "manual_review",
    reasons,
    checks,
  };
}

// Verification OCR feature: builds Firestore failure fields while preserving any partial OCR text.
export function buildFailurePayload(error: unknown, ocrText?: string): OcrFailurePayload {
  const message = readableErrorMessage(error);
  return {
    ocrStatus: OCR_STATUS_FAILED,
    adminStatus: ADMIN_STATUS_MANUAL_CHECK_REQUIRED,
    ocrError: message,
    ...(ocrText?.trim() ? {ocrText} : {}),
  };
}

// Verification OCR feature: converts thrown OCR/AI errors into admin-readable failure messages.
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

// Verification OCR feature: converts extracted fields into plain value maps for admin review forms.
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

// Verification OCR feature: extracts the first JSON object from Gemini output.
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

// Verification OCR feature: normalizes one Gemini field result into value/confidence shape.
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

// Verification OCR feature: keeps AI confidence values inside the 0..1 range.
function clampConfidence(value: unknown): number {
  if (typeof value !== "number" || Number.isNaN(value)) return 0.85;
  return Math.min(1, Math.max(0, value));
}

// Verification OCR feature: returns a human-readable document type for prompts.
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

// Verification OCR feature: limits OCR text size before sending it to Gemini.
function truncateForPrompt(value: string): string {
  const clean = value.trim();
  const maxChars = 60000;
  if (clean.length <= maxChars) return clean;
  return `${clean.slice(0, maxChars)}\n\n[Document text truncated after ${maxChars} characters]`;
}

// Verification OCR feature: safely trims unknown field values for comparisons.
function cleanString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

// Verification OCR feature: splits full names when first/last fields are unavailable.
function splitFallbackName(value: string): {firstName: string; lastName: string} {
  const parts = value.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return {firstName: "", lastName: ""};
  if (parts.length === 1) return {firstName: parts[0], lastName: ""};
  return {firstName: parts[0], lastName: parts.slice(1).join(" ")};
}

// Verification OCR feature: picks the best extracted name field based on document type.
function preferredNameField(
  documentType: VerificationDocumentType,
  fields: ExtractedVerificationFields,
): {key: string; field: ExtractedVerificationField} | null {
  const keys = documentType === "utilityBill" ?
    ["bill_holder_name", "resident_name", "tenant_name"] :
    documentType === "tenancyAgreement" ?
      ["tenant_name", "resident_name", "bill_holder_name"] :
      ["resident_name", "tenant_name", "bill_holder_name"];

  for (const key of keys) {
    const field = fields[key];
    if (field?.value.trim()) return {key, field};
  }
  return null;
}

// Verification OCR feature: normalizes text before name/community matching.
function normalizeTextForMatch(value: string): string {
  return value
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .replace(/\b(bin|binti|bt|bte|ibn|a\/l|a\/p|mr|mrs|ms|miss|dr)\b/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

// Verification OCR feature: checks whether extracted names contain expected first/last name tokens.
function nameContainsToken(normalizedName: string, expectedValue: string): boolean {
  const tokens = normalizeTextForMatch(expectedValue)
    .split(" ")
    .filter((token) => token.length >= 2);
  if (tokens.length === 0) return false;
  const nameTokens = new Set(normalizedName.split(" ").filter(Boolean));
  return tokens.every((token) => nameTokens.has(token));
}

// Verification OCR feature: normalizes unit numbers before comparing request data to OCR fields.
function normalizeUnit(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]/g, "");
}

// Verification OCR feature: checks whether OCR unit fields match the resident's submitted unit number.
function extractedUnitMatches(
  expectedUnit: string,
  documentType: VerificationDocumentType,
  fields: ExtractedVerificationFields,
): {check: AutoVerificationCheck} {
  const normalizedExpected = normalizeUnit(expectedUnit);
  if (!normalizedExpected) {
    return {check: {passed: false, expected: expectedUnit}};
  }

  const candidateKeys = documentType === "utilityBill" ?
    ["unit_number", "service_address", "property_address"] :
    ["unit_number", "property_address", "service_address"];

  for (const key of candidateKeys) {
    const field = fields[key];
    const value = field?.value.trim() ?? "";
    if (!value) continue;
    const normalizedValue = normalizeUnit(value);
    const confidenceOk = field ? field.confidence >= 0.8 : true;
    if (normalizedValue.includes(normalizedExpected) && confidenceOk) {
      return {
        check: {
          passed: true,
          expected: expectedUnit,
          actual: value,
          source: key,
        },
      };
    }
  }

  const actual = candidateKeys
    .map((key) => fields[key]?.value.trim())
    .filter((value): value is string => Boolean(value))
    .join(" | ");

  return {
    check: {
      passed: false,
      expected: expectedUnit,
      actual,
      source: candidateKeys.join(","),
    },
  };
}

// Verification OCR feature: records whether the resident email appears anywhere in OCR text.
function emailObservedCheck(expectedEmail: string, ocrText: string): AutoVerificationCheck {
  if (!expectedEmail) return {passed: true, skipped: true};
  const normalizedExpected = expectedEmail.toLowerCase();
  const emails = Array.from(ocrText.matchAll(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi))
    .map((match) => match[0].toLowerCase());
  if (emails.length === 0) {
    return {passed: true, expected: normalizedExpected, skipped: true};
  }
  return {
    passed: emails.includes(normalizedExpected),
    expected: normalizedExpected,
    actual: emails.join(", "),
  };
}

// Verification OCR feature: records whether the resident phone number appears anywhere in OCR text.
function phoneObservedCheck(expectedPhone: string, ocrText: string): AutoVerificationCheck {
  const expectedDigits = digitsOnly(expectedPhone);
  if (expectedDigits.length < 7) return {passed: true, skipped: true};

  const phones = Array.from(ocrText.matchAll(/(?:\+?\d[\d\s().-]{6,}\d)/g))
    .map((match) => digitsOnly(match[0]))
    .filter((value) => value.length >= 7);

  if (phones.length === 0) {
    return {passed: true, expected: expectedDigits, skipped: true};
  }

  const matched = phones.some((value) =>
    value.endsWith(expectedDigits) ||
    expectedDigits.endsWith(value) ||
    value.endsWith(expectedDigits.slice(-8)),
  );

  return {
    passed: matched,
    expected: expectedDigits,
    actual: phones.join(", "),
  };
}

// Verification OCR feature: records whether the selected community name appears in extracted fields or OCR text.
function communityObservedCheck(
  expectedCommunity: string,
  fields: ExtractedVerificationFields,
  ocrText: string,
): AutoVerificationCheck {
  if (!expectedCommunity) return {passed: true, skipped: true};

  const addressValues = [
    fields.property_address?.value.trim(),
    fields.service_address?.value.trim(),
  ].filter((value): value is string => Boolean(value));
  const haystack = normalizeTextForMatch([...addressValues, ocrText].join(" "));
  const expectedTokens = normalizeTextForMatch(expectedCommunity)
    .split(" ")
    .filter((token) =>
      token.length >= 3 &&
      !["residence", "residences", "resident", "condominium", "apartment"].includes(token),
    );

  if (expectedTokens.length === 0) {
    return {
      passed: true,
      expected: expectedCommunity,
      skipped: true,
    };
  }

  const passed = expectedTokens.every((token) => haystack.includes(token));
  return {
    passed,
    expected: expectedCommunity,
    actual: addressValues.join(" | "),
    source: "property_address,service_address,ocrText",
    skipped: addressValues.length === 0 && !passed,
  };
}

// Verification OCR feature: removes non-digits for phone and unit comparisons.
function digitsOnly(value: string): string {
  return value.replace(/\D/g, "");
}

// Verification OCR feature: guards JSON parsing to plain objects before reading Gemini fields.
function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
