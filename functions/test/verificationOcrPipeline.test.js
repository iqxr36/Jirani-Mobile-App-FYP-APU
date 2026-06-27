const assert = require("node:assert/strict");
const test = require("node:test");

const {
  ADMIN_STATUS_MANUAL_CHECK_REQUIRED,
  OCR_STATUS_COMPLETED,
  OCR_STATUS_FAILED,
  buildFailurePayload,
  buildSuccessPayload,
  normalizeDocumentAiDocument,
  parseGeminiExtraction,
  shouldStartVerificationOcr,
} = require("../lib/ocr/verificationOcrPipeline");

test("normalizes Document AI text and page count", () => {
  const result = normalizeDocumentAiDocument({
    text: "  Tenant Name: Nur Aisyah  ",
    pages: [{pageNumber: 1}, {pageNumber: 2}],
  });

  assert.deepEqual(result, {
    text: "Tenant Name: Nur Aisyah",
    pageCount: 2,
  });
});

test("parses fenced Gemini JSON into structured fields", () => {
  const fields = parseGeminiExtraction(
    `\`\`\`json
{
  "fields": {
    "tenant_name": {"value": "Nur Aisyah", "confidence": 0.92},
    "landlord_name": {"value": null, "confidence": 0.2},
    "unit_number": "A-18-07",
    "property_address": {"value": "Vista Harmoni", "confidence": 2}
  }
}
\`\`\``,
    "tenancyAgreement",
  );

  assert.equal(fields.tenant_name.value, "Nur Aisyah");
  assert.equal(fields.tenant_name.confidence, 0.92);
  assert.equal(fields.unit_number.value, "A-18-07");
  assert.equal(fields.unit_number.confidence, 0.85);
  assert.equal(fields.property_address.confidence, 1);
  assert.equal(fields.landlord_name, undefined);
});

test("builds success payload with field map and review status", () => {
  const payload = buildSuccessPayload({
    ocrText: "Account Number: 123",
    pageCount: 1,
    extractedFields: {
      account_number: {
        value: "123",
        confidence: 0.9,
        source: "gemini",
      },
    },
  });

  assert.equal(payload.ocrStatus, OCR_STATUS_COMPLETED);
  assert.equal(payload.adminStatus, "pending_review");
  assert.deepEqual(payload.ocrFields, {account_number: "123"});
  assert.equal(payload.documentAiPageCount, 1);
});

test("builds failed manual-review payload while preserving OCR text", () => {
  const payload = buildFailurePayload(
    new Error("Gemini returned invalid JSON"),
    "Readable text",
  );

  assert.equal(payload.ocrStatus, OCR_STATUS_FAILED);
  assert.equal(payload.adminStatus, ADMIN_STATUS_MANUAL_CHECK_REQUIRED);
  assert.equal(payload.ocrError, "Gemini returned invalid JSON");
  assert.equal(payload.ocrText, "Readable text");
});

test("starts OCR only after upload URL exists and request is pending", () => {
  assert.equal(
    shouldStartVerificationOcr(undefined, {
      status: "submitted",
      storagePath: "resident_documents/u/r/file.pdf",
      documentUrl: "https://example.com/file.pdf",
      ocrStatus: "pending",
    }),
    true,
  );

  assert.equal(
    shouldStartVerificationOcr(undefined, {
      status: "submitted",
      storagePath: "resident_documents/u/r/file.pdf",
      documentUrl: "",
      ocrStatus: "pending",
    }),
    false,
  );

  assert.equal(
    shouldStartVerificationOcr(
      {ocrStatus: "processing"},
      {
        status: "submitted",
        storagePath: "resident_documents/u/r/file.pdf",
        documentUrl: "https://example.com/file.pdf",
        ocrStatus: "processing",
      },
    ),
    false,
  );
});
