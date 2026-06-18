export const UTILITY_BILL_FIELD_KEYS = [
  "account_number",
  "bill_date",
  "bill_holder_name",
  "due_date",
  "service_address",
  "total_amount",
  "utility_issuer_or_provider",
  "utility_type",
] as const;

export type UtilityBillFieldKey = (typeof UTILITY_BILL_FIELD_KEYS)[number];
export type UtilityExtractionSource = "document_ai" | "fallback_parser";

export type UtilityExtractedField = {
  value: string;
  confidence: number;
  source: UtilityExtractionSource;
};

export type UtilityExtractedFields = Partial<
  Record<UtilityBillFieldKey, UtilityExtractedField>
>;

export type UtilityMergeResult = {
  fields: UtilityExtractedFields;
  suspiciousFields: Partial<Record<UtilityBillFieldKey, string>>;
  fallbackFixes: Partial<Record<UtilityBillFieldKey, string>>;
};

const CONFIDENCE_THRESHOLD = 0.75;
const FALLBACK_CONFIDENCE = 0.7;
const REQUIRED_UTILITY_FIELDS: readonly UtilityBillFieldKey[] = [
  "bill_holder_name",
  "utility_issuer_or_provider",
  "service_address",
  "total_amount",
];

export function validateUtilityBillFields(
  fields: UtilityExtractedFields,
  fullText = "",
): Partial<Record<UtilityBillFieldKey, string>> {
  const issues: Partial<Record<UtilityBillFieldKey, string>> = {};

  for (const key of UTILITY_BILL_FIELD_KEYS) {
    const field = fields[key];
    const value = field?.value.trim() ?? "";
    if (!value) {
      issues[key] = "missing";
      continue;
    }
    if (
      field?.source !== "fallback_parser" &&
      (field?.confidence ?? 0) < CONFIDENCE_THRESHOLD
    ) {
      issues[key] = "low_confidence";
      continue;
    }

    if ((key === "bill_date" || key === "due_date") && !looksLikeDate(value)) {
      issues[key] = "invalid_date";
      continue;
    }
    if (key === "due_date" && looksLikeDateLabelNoise(value)) {
      issues[key] = "date_label_noise";
      continue;
    }
    if (key === "total_amount" && !looksLikeAmount(value)) {
      issues[key] = "invalid_amount";
      continue;
    }
    if (key === "service_address" && !looksLikeAddress(value)) {
      issues[key] = "invalid_address";
      continue;
    }
    if (
      key === "utility_issuer_or_provider" &&
      !looksLikeExplicitProvider(value, fullText)
    ) {
      issues[key] = "provider_not_explicit";
      continue;
    }
    if (key === "utility_type" && looksLikeGenericUtilityType(value, fullText)) {
      issues[key] = "generic_utility_type";
    }
  }

  return issues;
}

export function fallbackExtractUtilityProvider(
  fullText: string,
): string | undefined {
  const text = cleanText(fullText);
  const patterns = [
    /\bUtility\s+Issuer\s*\/\s*Provider\s+(.+?)(?=\n|$)/i,
    /\bIssued\s+By\s*\/\s*Utility\s*\n?\s*Provider\s+(.+?)(?=\n|$)/i,
    /\bUtility\s+Provider\s+(.+?)(?=\n|$)/i,
    /\bBill\s+Issuer\s+(.+?)(?=\n|$)/i,
    /\bManagement\s+Company\s+(.+?)(?=\n|$)/i,
    /\bProvider\s+(.+?)(?=\n|$)/i,
    /\bIssued\s+By\s+(.+?)(?=\s+TOTAL\s+AMOUNT|\n|$)/i,
    /\bLandlord\s+(.+?)(?=\n|$)/i,
    /\bOwner\s+(.+?)(?=\n|$)/i,
    /\bCompany\s+(.+?)(?=\n|$)/i,
  ];

  for (const pattern of patterns) {
    const value = cleanValue(text.match(pattern)?.[1]);
    if (value && !isProviderGuess(value, text)) return trimProviderValue(value);
  }

  return undefined;
}

export function fallbackExtractServiceAddress(
  fullText: string,
): string | undefined {
  const lines = nonEmptyLines(fullText);
  const labels = [
    ["Service Address"],
    ["Supply Address"],
    ["Premise Address"],
    ["Premises Address"],
    ["Premise / Service", "Address"],
    ["Supply / Service", "Address"],
    ["Property Address"],
    ["Installation Address"],
    ["Address"],
  ];

  for (const labelParts of labels) {
    const value = extractAfterLabelParts(lines, labelParts, {
      multiline: true,
      stopLabels: addressStopLabels(),
    });
    if (value && looksLikeAddress(value)) return value;
  }

  return undefined;
}

export function fallbackExtractDueDate(fullText: string): string | undefined {
  return extractDateAfterLabels(fullText, [
    ["Last Payment Date / Due", "Date"],
    ["Last Payment Date / Due Date"],
    ["Payment Due Date"],
    ["Last Payment Date"],
    ["Due Date"],
  ]);
}

export function fallbackExtractBillDate(fullText: string): string | undefined {
  return extractDateAfterLabels(fullText, [
    ["Bill Issue Date"],
    ["Bill Date"],
    ["Invoice Date"],
    ["Statement Date"],
    ["Billing Date"],
    ["Issue Date"],
  ]);
}

export function fallbackExtractUtilityType(
  fullText: string,
): string | undefined {
  const lines = nonEmptyLines(fullText);
  const value = extractAfterLabelParts(lines, ["Utility Type"], {
    multiline: false,
    stopLabels: ["Reference", "Account", "Bill Date", "Due Date"],
  });
  if (value) return normalizeUtilityType(value);

  const normalized = normalizeSearch(fullText);
  const knownTypes = [
    "Monthly House Rent",
    "Maintenance",
    "Electricity",
    "Internet",
    "Sewage",
    "Water",
    "Rent",
    "Gas",
  ];
  return knownTypes.find((type) => normalized.includes(normalizeSearch(type)));
}

export function fallbackExtractTotalAmount(fullText: string): string | undefined {
  const labels = [
    "TOTAL AMOUNT PAYABLE",
    "Total Paid",
    "Total Amount",
    "Total Payable",
    "Amount Due",
    "Balance Due",
    "Subtotal",
  ];
  const lines = nonEmptyLines(fullText);
  for (const label of labels) {
    const normalizedLabel = normalizeSearch(label);
    const line = lines.find((value) =>
      normalizeSearch(value).includes(normalizedLabel),
    );
    const amount = extractAmount(line);
    if (amount) return amount;
    const index = lines.findIndex((value) =>
      normalizeSearch(value).includes(normalizedLabel),
    );
    if (index >= 0) {
      const nextAmount = extractAmount(lines[index + 1]);
      if (nextAmount) return nextAmount;
    }
  }
  return undefined;
}

export function fallbackExtractBillHolderName(
  fullText: string,
): string | undefined {
  const lines = nonEmptyLines(fullText);
  const value = extractAfterLabelParts(lines, ["Bill Holder Name"], {
    multiline: false,
    stopLabels: fieldStopLabels(),
  }) ?? extractAfterLabelParts(lines, ["Billed To / Bill Holder", "Name"], {
    multiline: false,
    stopLabels: fieldStopLabels(),
  }) ?? extractAfterLabelParts(lines, ["Customer / Bill Holder", "Name"], {
    multiline: false,
    stopLabels: fieldStopLabels(),
  });
  return value;
}

export function mergeDocumentAiWithFallback(
  documentAiFields: UtilityExtractedFields,
  fullText: string,
): UtilityMergeResult {
  const fields: UtilityExtractedFields = {...documentAiFields};
  const suspiciousFields = validateUtilityBillFields(fields, fullText);
  const fallbackFixes: Partial<Record<UtilityBillFieldKey, string>> = {};
  const fallbackByField: Partial<Record<UtilityBillFieldKey, () => string | undefined>> = {
    bill_date: () => fallbackExtractBillDate(fullText),
    bill_holder_name: () => fallbackExtractBillHolderName(fullText),
    due_date: () => fallbackExtractDueDate(fullText),
    service_address: () => fallbackExtractServiceAddress(fullText),
    total_amount: () => fallbackExtractTotalAmount(fullText),
    utility_issuer_or_provider: () => fallbackExtractUtilityProvider(fullText),
    utility_type: () => fallbackExtractUtilityType(fullText),
  };

  for (const key of UTILITY_BILL_FIELD_KEYS) {
    const issue = suspiciousFields[key];
    if (!issue) continue;
    const fallback = fallbackByField[key]?.();
    if (!fallback) continue;

    fields[key] = {
      value: fallback,
      confidence: FALLBACK_CONFIDENCE,
      source: "fallback_parser",
    };
    fallbackFixes[key] = fallback;
  }

  return {
    fields,
    suspiciousFields: validateUtilityBillFields(fields, fullText),
    fallbackFixes,
  };
}

export function needsUtilityManualReview(
  fields: UtilityExtractedFields,
  fullText = "",
): boolean {
  const issues = validateUtilityBillFields(fields, fullText);
  return REQUIRED_UTILITY_FIELDS.some((key) => Boolean(issues[key]));
}

function extractDateAfterLabels(
  fullText: string,
  labelPartsList: string[][],
): string | undefined {
  const lines = nonEmptyLines(fullText);
  for (const labelParts of labelPartsList) {
    const value = extractAfterLabelParts(lines, labelParts, {
      multiline: false,
      stopLabels: fieldStopLabels(),
    });
    const date = extractDate(value);
    if (date) return date;
  }
  return undefined;
}

function extractAfterLabelParts(
  lines: string[],
  labelParts: string[],
  options: {multiline: boolean; stopLabels: string[]},
): string | undefined {
  for (let index = 0; index < lines.length; index++) {
    const inline = extractInlineAfterLabel(lines[index], labelParts.join(" "));
    if (inline) {
      return options.multiline ?
        collectContinuation(inline, lines, index, options.stopLabels) :
        inline;
    }

    if (!matchesLabelPart(lines[index], labelParts[0])) continue;
    let cursor = index + 1;
    let matched = true;
    for (let partIndex = 1; partIndex < labelParts.length; partIndex++) {
      if (!matchesLabelPart(lines[cursor] ?? "", labelParts[partIndex])) {
        matched = false;
        break;
      }
      cursor++;
    }
    if (!matched) continue;

    const inlineFromLastPart = extractInlineAfterLabel(
      lines[cursor - 1] ?? "",
      labelParts[labelParts.length - 1],
    );
    if (inlineFromLastPart) return inlineFromLastPart;

    const firstValue = cleanValue(lines[cursor]);
    if (!firstValue || isStopLine(firstValue, options.stopLabels)) continue;
    return options.multiline ?
      collectContinuation(firstValue, lines, cursor, options.stopLabels) :
      firstValue;
  }
  return undefined;
}

function extractInlineAfterLabel(line: string, label: string): string | undefined {
  const pattern = new RegExp(`^${escapeRegExp(label)}\\s*[:/-]?\\s+(.+)$`, "i");
  return cleanValue(line.match(pattern)?.[1]);
}

function collectContinuation(
  firstValue: string,
  lines: string[],
  startIndex: number,
  stopLabels: string[],
): string {
  const parts = [firstValue];
  for (let index = startIndex + 1; index < lines.length; index++) {
    const value = cleanValue(lines[index]);
    if (!value || isStopLine(value, stopLabels)) break;
    parts.push(value);
  }
  return parts.join(" ").replace(/\s+/g, " ").trim();
}

function matchesLabelPart(line: string, label: string): boolean {
  return normalizeSearch(line) === normalizeSearch(label);
}

function isStopLine(line: string, stopLabels: string[]): boolean {
  const normalized = normalizeSearch(line);
  return stopLabels.some((label) => normalized.startsWith(normalizeSearch(label)));
}

function looksLikeDate(value: string): boolean {
  return Boolean(extractDate(value));
}

function looksLikeDateLabelNoise(value: string): boolean {
  const normalized = normalizeSearch(value);
  return [
    "premise / service",
    "premise service",
    "address",
    "date",
    "due",
    "last payment date / due",
  ].some((label) => normalized === normalizeSearch(label));
}

function looksLikeAmount(value: string): boolean {
  return /\b(?:RM|MYR)?\s*\d{1,3}(?:,\d{3})*(?:\.\d{2})?\b/i.test(value);
}

function looksLikeAddress(value: string): boolean {
  const normalized = normalizeSearch(value);
  const hasAddressCue = /\b(unit|jalan|street|avenue|condominium|residence|kuala lumpur|bukit|postcode|malaysia)\b/i.test(
    value,
  );
  const hasMultipleParts = value.split(",").length >= 2;
  const hasPostcode = /\b\d{5}\b/.test(value);
  return normalized.length >= 12 && (hasAddressCue || hasMultipleParts || hasPostcode);
}

function looksLikeExplicitProvider(value: string, fullText: string): boolean {
  if (isProviderGuess(value, fullText)) return false;
  return normalizeSearch(fullText).includes(normalizeSearch(value));
}

function isProviderGuess(value: string, fullText: string): boolean {
  const normalized = normalizeSearch(value);
  const standaloneGuesses = [
    "internet",
    "electricity",
    "water",
    "rent",
    "unifi",
  ];
  if (!standaloneGuesses.includes(normalized)) return false;

  const explicitProviderPattern = new RegExp(
    `(issued by|provider|utility provider|bill issuer|management company|landlord|owner|company)\\s+.{0,40}${escapeRegExp(value)}`,
    "i",
  );
  return !explicitProviderPattern.test(fullText);
}

function looksLikeGenericUtilityType(value: string, fullText: string): boolean {
  if (normalizeSearch(value) !== "other") return false;
  return [
    "Monthly House Rent",
    "Maintenance",
    "Electricity",
    "Internet",
    "Sewage",
    "Water",
    "Rent",
    "Gas",
  ].some((type) => normalizeSearch(fullText).includes(normalizeSearch(type)));
}

function normalizeUtilityType(value: string): string {
  const knownTypes = [
    "Monthly House Rent",
    "Maintenance",
    "Electricity",
    "Internet",
    "Sewage",
    "Water",
    "Rent",
    "Gas",
  ];
  const normalized = normalizeSearch(value);
  return knownTypes.find((type) => normalized.includes(normalizeSearch(type))) ??
    value;
}

function trimProviderValue(value: string): string {
  return value
    .replace(/\s+TOTAL\s+AMOUNT.*$/i, "")
    .replace(/\s+Bill Details.*$/i, "")
    .trim();
}

function extractDate(value?: string): string | undefined {
  return cleanValue(
    value?.match(
      /\b(\d{1,2}[\/\-.]\d{1,2}[\/\-.]\d{2,4}|\d{4}[\/\-.]\d{1,2}[\/\-.]\d{1,2}|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{1,2},?\s+\d{4}|\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{4})\b/i,
    )?.[0],
  );
}

function extractAmount(value?: string): string | undefined {
  const match = value?.match(/\b(RM|MYR)\s*([0-9][0-9,]*(?:\.\d{1,2})?)\b/i);
  if (match?.[1] && match[2]) return `${match[1].toUpperCase()} ${match[2]}`;
  return value?.match(/\b\d{1,3}(?:,\d{3})*(?:\.\d{2})\b/)?.[0];
}

function cleanText(value: string): string {
  return value
    .replace(/\r/g, "\n")
    .split("\n")
    .map((line) => line.replace(/[ \t]+/g, " ").trim())
    .join("\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function nonEmptyLines(value: string): string[] {
  return cleanText(value)
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.length > 0);
}

function cleanValue(value?: string): string | undefined {
  const trimmed = value?.replace(/[ \t]+/g, " ").trim();
  return trimmed ? trimmed.replace(/^[\s:;|]+|[\s;|]+$/g, "").trim() : undefined;
}

function normalizeSearch(value: string): string {
  return value.toLowerCase().replace(/\s+/g, " ").trim();
}

function fieldStopLabels(): string[] {
  return [
    "Account Number",
    "Bill Date",
    "Billing Date",
    "Invoice Date",
    "Statement Date",
    "Due Date",
    "Payment Due Date",
    "Last Payment Date",
    "Service Address",
    "Supply Address",
    "Premise",
    "Premises",
    "Property Address",
    "Utility Type",
    "Utility Provider",
    "Utility Issuer",
    "Provider",
    "Charges Summary",
    "Notes",
  ];
}

function addressStopLabels(): string[] {
  return [
    ...fieldStopLabels(),
    "Meter Number",
    "Rental Unit Number",
    "Contact Email",
    "Lease Reference",
  ];
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
