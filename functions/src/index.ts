import {v1 as documentai} from "@google-cloud/documentai";
import {ImageAnnotatorClient} from "@google-cloud/vision";
import * as admin from "firebase-admin";
import {FieldValue} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {setGlobalOptions} from "firebase-functions/v2";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onObjectFinalized} from "firebase-functions/v2/storage";

import {type VerificationRequestData} from "./ocr/extractFields";
import {
  mergeDocumentAiWithFallback,
  needsUtilityManualReview,
  UTILITY_BILL_FIELD_KEYS,
  type UtilityBillFieldKey,
  type UtilityExtractedFields,
} from "./ocr/utilityBillExtractionHelper";

admin.initializeApp();
setGlobalOptions({maxInstances: 10, region: "asia-southeast1"});

const PROJECT_ID = "final-year-project-faisal";
const LOCATION = "asia-southeast1";
const TENANCY_AGREEMENT_PROCESSOR_ID = "f68b8fdbbd030f1f";
const TENANCY_AGREEMENT_PROCESSOR_VERSION_ID = "314ca3ea3abd1329";
const UTILITY_BILL_PROCESSOR_ID = "PASTE_UTILITY_PROCESSOR_ID_HERE";
const UTILITY_BILL_PROCESSOR_VERSION_ID = "db22b8727da077b1";
const DOCUMENT_AI_ENDPOINT = `${LOCATION}-documentai.googleapis.com`;
const MANUAL_CHECK_CONFIDENCE_THRESHOLD = 0.75;
const RESIDENT_DOCUMENTS_PREFIX = "resident_documents/";
const DOCUMENT_TYPE_TENANCY_AGREEMENT = "tenancyAgreement";
const DOCUMENT_TYPE_UTILITY_BILL = "utilityBill";
const DOCUMENT_TYPE_ACCESS_CARD = "accessCard";
const DOCUMENT_TYPE_OTHER_PROOF = "otherProof";
const OCR_SETTINGS_COLLECTION = "appSettings";
const OCR_SETTINGS_DOCUMENT = "ocr";
const TENANCY_AGREEMENT_FIELD_KEYS = [
  "tenant_name",
  "landlord_name",
  "unit_number",
  "agreement_date",
  "property_address",
] as const;
type TenancyAgreementFieldKey =
  (typeof TENANCY_AGREEMENT_FIELD_KEYS)[number];
type ExtractedFieldKey = TenancyAgreementFieldKey | UtilityBillFieldKey;

type DocumentProcessorConfig = {
  documentType: string;
  processorId: string;
  processorVersionId: string;
  requiredFieldKeys: readonly ExtractedFieldKey[];
  fieldLabels: Partial<Record<ExtractedFieldKey, string>>;
};

const TENANCY_AGREEMENT_PROCESSOR_CONFIG: DocumentProcessorConfig = {
  documentType: DOCUMENT_TYPE_TENANCY_AGREEMENT,
  processorId: TENANCY_AGREEMENT_PROCESSOR_ID,
  processorVersionId: TENANCY_AGREEMENT_PROCESSOR_VERSION_ID,
  requiredFieldKeys: TENANCY_AGREEMENT_FIELD_KEYS,
  fieldLabels: {
    tenant_name: "Tenant Name",
    landlord_name: "Landlord Name",
    unit_number: "Unit Number",
    agreement_date: "Agreement Date",
    property_address: "Property Address",
  },
};

const UTILITY_BILL_PROCESSOR_CONFIG: DocumentProcessorConfig = {
  documentType: DOCUMENT_TYPE_UTILITY_BILL,
  processorId: UTILITY_BILL_PROCESSOR_ID,
  processorVersionId: UTILITY_BILL_PROCESSOR_VERSION_ID,
  requiredFieldKeys: UTILITY_BILL_FIELD_KEYS,
  fieldLabels: {
    account_number: "Account Number",
    bill_date: "Bill Date",
    bill_holder_name: "Bill Holder Name",
    due_date: "Due Date",
    service_address: "Service Address",
    total_amount: "Total Amount",
    utility_issuer_or_provider: "Utility Provider",
    utility_type: "Utility Type",
  },
};

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

type ExtractionSource = "document_ai" | "fallback_parser";

type ExtractedField = {
  value: string;
  confidence: number;
  source: ExtractionSource;
};

type ExtractedFields = Partial<Record<ExtractedFieldKey, ExtractedField>>;

type ExtractionResult = {
  text: string;
  fields: ExtractedFields;
  provider: "document_ai" | "ocr_fallback";
  documentAiUsed: boolean;
  fallbackUsed: boolean;
  processorVersion?: string;
  processorDocumentType?: string;
};

type OcrRuntimeSettings = {
  autoProcessingEnabled: boolean;
  documentAiEnabled: boolean;
  visionFallbackEnabled: boolean;
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
  const settings = await loadOcrRuntimeSettings();
  if (!settings.autoProcessingEnabled) {
    await markAutomaticExtractionSkipped({
      requestRef: args.requestRef,
      reason:
        "Automatic OCR is disabled. Review this document manually, or enable " +
        "appSettings/ocr.autoProcessingEnabled when you want extraction to run.",
      settings,
    });
    return;
  }

  const processorConfig = processorConfigForDocumentType(
    args.requestData.documentType,
  );
  if (!processorConfig && !settings.visionFallbackEnabled) {
    await markAutomaticExtractionSkipped({
      requestRef: args.requestRef,
      reason:
        "No Document AI processor is configured for this document type, and " +
        "Vision OCR fallback is disabled. Review this document manually.",
      settings,
    });
    return;
  }

  if (processorConfig && !settings.documentAiEnabled &&
      !settings.visionFallbackEnabled) {
    await markAutomaticExtractionSkipped({
      requestRef: args.requestRef,
      reason:
        "Document AI is disabled in appSettings/ocr.documentAiEnabled and " +
        "Vision OCR fallback is disabled. Review this document manually.",
      settings,
    });
    return;
  }

  const mimeType = mimeTypeForPath(args.storagePath);
  const extraction = await extractDocumentFields({
    bucketName: args.bucketName,
    storagePath: args.storagePath,
    mimeType,
    requestId: args.requestId,
    requestData: args.requestData,
    settings,
  });

  const trimmedText = extraction.text.trim();
  if (!trimmedText && Object.keys(extraction.fields).length === 0) {
    throw new Error("No readable text or fields were detected in this document.");
  }

  let finalFields = extraction.fields;
  let needsManualCheck = requiresManualCheck(
    finalFields,
    processorConfig?.requiredFieldKeys ?? [],
  );
  let fieldFallbackUsed = false;

  if (processorConfig?.documentType === DOCUMENT_TYPE_UTILITY_BILL) {
    logger.info("Utility bill raw Document AI fields", {
      requestId: args.requestId,
      fields: loggableFields(extraction.fields),
    });
    const mergeResult = mergeDocumentAiWithFallback(
      extraction.fields as UtilityExtractedFields,
      trimmedText,
    );
    finalFields = mergeResult.fields as ExtractedFields;
    fieldFallbackUsed = Object.keys(mergeResult.fallbackFixes).length > 0;
    needsManualCheck = needsUtilityManualReview(mergeResult.fields, trimmedText);
    logger.info("Utility bill fallback merge completed", {
      requestId: args.requestId,
      suspiciousFields: mergeResult.suspiciousFields,
      fallbackFixes: mergeResult.fallbackFixes,
      finalFields: loggableFields(finalFields),
      adminStatus: needsManualCheck ? "manual_check_required" : "pending_review",
    });
  }

  const ocrFields = extractedFieldsToOcrFields(
    finalFields,
    processorConfig,
  );

  await args.requestRef.update({
    adminStatus: needsManualCheck ? "manual_check_required" : "pending_review",
    extractedFields: finalFields,
    extractionProvider: extraction.provider,
    documentAi: {
      processorVersion: extraction.processorVersion ?? null,
      processorDocumentType: extraction.processorDocumentType ?? null,
      used: extraction.documentAiUsed,
      fallbackUsed: extraction.fallbackUsed,
      fieldFallbackUsed,
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
    processorDocumentType: extraction.processorDocumentType,
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

async function loadOcrRuntimeSettings(): Promise<OcrRuntimeSettings> {
  const snapshot = await db
    .collection(OCR_SETTINGS_COLLECTION)
    .doc(OCR_SETTINGS_DOCUMENT)
    .get();
  const data = snapshot.data();

  return {
    autoProcessingEnabled: readBooleanSetting(
      data?.autoProcessingEnabled,
      readBooleanEnv("OCR_AUTO_PROCESSING_ENABLED", false),
    ),
    documentAiEnabled: readBooleanSetting(
      data?.documentAiEnabled,
      readBooleanEnv("DOCUMENT_AI_ENABLED", false),
    ),
    visionFallbackEnabled: readBooleanSetting(
      data?.visionFallbackEnabled,
      readBooleanEnv("VISION_OCR_FALLBACK_ENABLED", false),
    ),
  };
}

function readBooleanEnv(name: string, fallback: boolean): boolean {
  return readBooleanSetting(process.env[name], fallback);
}

function readBooleanSetting(value: unknown, fallback: boolean): boolean {
  if (typeof value === "boolean") return value;
  if (typeof value !== "string") return fallback;

  const normalized = value.trim().toLowerCase();
  if (["1", "true", "yes", "on", "enabled"].includes(normalized)) return true;
  if (["0", "false", "no", "off", "disabled"].includes(normalized)) {
    return false;
  }
  return fallback;
}

async function markAutomaticExtractionSkipped(args: {
  requestRef: admin.firestore.DocumentReference;
  reason: string;
  settings: OcrRuntimeSettings;
}) {
  await args.requestRef.update({
    ocrStatus: "pending",
    adminStatus: "manual_check_required",
    ocrError: args.reason,
    errorMessage: args.reason,
    documentAi: {
      used: false,
      fallbackUsed: false,
      fieldFallbackUsed: false,
      disabledBySettings: true,
      settings: args.settings,
    },
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
  settings: OcrRuntimeSettings;
}): Promise<ExtractionResult> {
  const processorConfig = processorConfigForDocumentType(
    args.requestData.documentType,
  );
  if (!processorConfig) {
    if (!args.settings.visionFallbackEnabled) {
      throw new Error(
        "No Document AI processor is configured for this document type, " +
        "and Vision OCR fallback is disabled.",
      );
    }
    logger.info("No Document AI processor configured; using OCR fallback", {
      requestId: args.requestId,
      documentType: args.requestData.documentType,
    });
    const fallback = await extractWithVisionOcr(args);
    return {
      ...fallback,
      provider: "ocr_fallback",
      documentAiUsed: false,
      fallbackUsed: true,
    };
  }

  if (!args.settings.documentAiEnabled) {
    if (!args.settings.visionFallbackEnabled) {
      throw new Error(
        "Document AI is disabled in appSettings/ocr.documentAiEnabled and " +
        "Vision OCR fallback is disabled.",
      );
    }
    logger.info("Document AI disabled; using OCR fallback", {
      requestId: args.requestId,
      documentType: args.requestData.documentType,
    });
    const fallback = await extractWithVisionOcr(args);
    return {
      ...fallback,
      provider: "ocr_fallback",
      documentAiUsed: false,
      fallbackUsed: true,
    };
  }

  try {
    const documentAiResult = await extractWithDocumentAi({
      ...args,
      processorConfig,
    });
    return {
      ...documentAiResult,
      provider: "document_ai",
      documentAiUsed: true,
      fallbackUsed: false,
      processorVersion: processorVersionName(processorConfig),
      processorDocumentType: processorConfig.documentType,
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

    if (!args.settings.visionFallbackEnabled) {
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

function processorConfigForDocumentType(
  documentType: string | undefined,
): DocumentProcessorConfig | undefined {
  switch (normalizeFieldName(documentType ?? "")) {
  case "tenancyagreement":
    return TENANCY_AGREEMENT_PROCESSOR_CONFIG;
  case "utilitybill":
    return UTILITY_BILL_PROCESSOR_CONFIG;
  default:
    return undefined;
  }
}

function processorVersionName(config: DocumentProcessorConfig): string {
  return `projects/${PROJECT_ID}/locations/${LOCATION}/processors/` +
    `${config.processorId}/processorVersions/${config.processorVersionId}`;
}

function assertProcessorConfigured(config: DocumentProcessorConfig) {
  if (config.processorId.includes("PASTE_")) {
    throw new Error(
      `${config.documentType} Document AI processor ID is not configured.`,
    );
  }
}

async function extractWithDocumentAi(args: {
  bucketName: string;
  storagePath: string;
  mimeType: string;
  processorConfig: DocumentProcessorConfig;
}): Promise<Omit<ExtractionResult, "provider" | "documentAiUsed" | "fallbackUsed">> {
  assertProcessorConfigured(args.processorConfig);
  const bucket = storage.bucket(args.bucketName);
  const [fileBuffer] = await bucket.file(args.storagePath).download();
  const processorVersion = processorVersionName(args.processorConfig);
  const [result] = await documentAiClient.processDocument({
    name: processorVersion,
    rawDocument: {
      content: fileBuffer.toString("base64"),
      mimeType: args.mimeType,
    },
    skipHumanReview: true,
  });
  const document = result.document as DocumentAiDocument | undefined;
  return {
    text: document?.text ?? "",
    fields: extractDocumentAiFields(document, args.processorConfig),
    processorVersion,
    processorDocumentType: args.processorConfig.documentType,
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

function extractDocumentAiFields(
  document: DocumentAiDocument | undefined,
  processorConfig: DocumentProcessorConfig,
): ExtractedFields {
  const fields: ExtractedFields = {};
  for (const entity of document?.entities ?? []) {
    collectDocumentAiEntity(fields, entity, processorConfig);
  }
  return fields;
}

function collectDocumentAiEntity(
  fields: ExtractedFields,
  entity: DocumentAiEntity,
  processorConfig: DocumentProcessorConfig,
) {
  const key = fieldKeyForDocumentAiType(entity.type ?? "", processorConfig);
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
    collectDocumentAiEntity(fields, property, processorConfig);
  }
}

function fieldKeyForDocumentAiType(
  type: string,
  processorConfig: DocumentProcessorConfig,
): ExtractedFieldKey | undefined {
  const normalized = normalizeFieldName(type);
  if (!normalized) return undefined;
  for (const key of processorConfig.requiredFieldKeys) {
    if (normalizeFieldName(key) === normalized) return key;
  }

  if (processorConfig.documentType === DOCUMENT_TYPE_UTILITY_BILL) {
    return fieldKeyForUtilityBillType(normalized);
  }

  return fieldKeyForTenancyAgreementType(normalized);
}

function fieldKeyForUtilityBillType(
  normalized: string,
): UtilityBillFieldKey | undefined {
  if (
    normalized.includes("accountnumber") ||
    normalized.includes("accountno") ||
    normalized.includes("customernumber") ||
    normalized.includes("contractaccount")
  ) {
    return "account_number";
  }
  if (
    normalized.includes("billdate") ||
    normalized.includes("billingdate") ||
    normalized.includes("invoicedate") ||
    normalized.includes("statementdate")
  ) {
    return "bill_date";
  }
  if (
    normalized.includes("tenant") ||
    normalized.includes("billholder") ||
    normalized.includes("customername") ||
    normalized.includes("accountname") ||
    normalized.includes("registeredname")
  ) {
    return "bill_holder_name";
  }
  if (
    normalized.includes("duedate") ||
    normalized.includes("paymentduedate") ||
    normalized.includes("paybydate")
  ) {
    return "due_date";
  }
  if (
    normalized.includes("serviceaddress") ||
    normalized.includes("supplyaddress") ||
    normalized.includes("premisesaddress") ||
    normalized.includes("propertyaddress") ||
    normalized.includes("billingaddress")
  ) {
    return "service_address";
  }
  if (
    normalized.includes("totalamount") ||
    normalized.includes("amountdue") ||
    normalized.includes("totalpayable") ||
    normalized.includes("balancedue") ||
    normalized.includes("currentcharges") ||
    normalized === "amount"
  ) {
    return "total_amount";
  }
  if (
    normalized.includes("utilityissuer") ||
    normalized.includes("utilityprovider") ||
    normalized.includes("provider") ||
    normalized.includes("issuer") ||
    normalized.includes("supplier")
  ) {
    return "utility_issuer_or_provider";
  }
  if (
    normalized.includes("utilitytype") ||
    normalized.includes("billtype") ||
    normalized.includes("servicetype")
  ) {
    return "utility_type";
  }
  return undefined;
}

function fieldKeyForTenancyAgreementType(
  normalized: string,
): TenancyAgreementFieldKey | undefined {
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

function extractedFieldsToOcrFields(
  fields: ExtractedFields,
  processorConfig: DocumentProcessorConfig | undefined,
): Record<string, string> {
  const result: Record<string, string> = {};
  const mappings = processorConfig?.requiredFieldKeys.map((key) => {
    return [key, processorConfig.fieldLabels[key] ?? key] as const;
  }) ?? [];

  for (const [fieldKey, label] of mappings) {
    const value = fields[fieldKey]?.value.trim();
    if (value) result[label] = value;
  }
  return result;
}

function loggableFields(fields: ExtractedFields): Record<string, unknown> {
  return Object.fromEntries(
    Object.entries(fields).map(([key, field]) => [
      key,
      field ?
        {
          value: field.value,
          confidence: field.confidence,
          source: field.source,
        } :
        null,
    ]),
  );
}

function assignField(
  fields: ExtractedFields,
  key: ExtractedFieldKey,
  field: ExtractedField,
) {
  const existing = fields[key];
  if (!existing || field.confidence > existing.confidence) {
    fields[key] = field;
  }
}

function requiresManualCheck(
  fields: ExtractedFields,
  requiredFieldKeys: readonly ExtractedFieldKey[],
): boolean {
  if (requiredFieldKeys.length === 0) return true;
  return requiredFieldKeys.some((key) => {
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
