export type OcrFields = Record<string, string>;

export interface VerificationRequestData {
  documentType?: string;
  fullName?: string;
  unitNumber?: string;
  communityName?: string;
}

const DOCUMENT_TYPE_UTILITY_BILL = "utilityBill";
const DOCUMENT_TYPE_TENANCY_AGREEMENT = "tenancyAgreement";
const DOCUMENT_TYPE_ACCESS_CARD = "accessCard";

export function extractOcrFields(
  rawText: string,
  request: VerificationRequestData,
): OcrFields {
  const fields: OcrFields = {};
  const text = cleanOcrText(rawText);
  const lines = nonEmptyLines(text);

  const fallbackDate = extractDate(text);

  const fullName = request.fullName?.trim();
  const unitNumber = request.unitNumber?.trim();

  switch (request.documentType) {
    case DOCUMENT_TYPE_TENANCY_AGREEMENT:
      extractTenancyAgreementFields(text, lines, fields, request);
      if (fallbackDate && !fields["Agreement Date"]) {
        fields["Agreement Date"] = fallbackDate;
      }
      break;
    case DOCUMENT_TYPE_UTILITY_BILL:
      extractUtilityBillFields(text, lines, fields, request);
      if (fallbackDate && !fields["Bill Date"]) fields["Bill Date"] = fallbackDate;
      break;
    case DOCUMENT_TYPE_ACCESS_CARD:
      extractAccessCardFields(text, lines, fields, request);
      break;
    default:
      if (fullName && textContains(text, fullName)) fields["Name"] = fullName;
      if (unitNumber && textContains(text, unitNumber)) {
        fields["Unit Number"] = unitNumber;
      }
      break;
  }

  return fields;
}

function extractTenancyAgreementFields(
  text: string,
  lines: string[],
  fields: OcrFields,
  request: VerificationRequestData,
) {
  const detailLines = nonEmptyLines(tenancyDetailsText(text));
  const tenant = sentenceValue(text, /\bTenant\s+Name\s+is\s+([^.\n,;]+)/i) ||
    extractByLabels(detailLines, [
      "Tenant Name",
      "Name of Tenant",
      "Resident Name",
      "Occupant Name",
      "Lessee",
      "Tenant",
    ]);

  if (tenant) fields["Tenant Name"] = tenant;

  const landlord =
    sentenceValue(text, /\bLandlord\s+Name\s+is\s+([^.\n,;]+)/i) ||
    extractByLabels(detailLines, [
      "Landlord Name",
      "Landlord / Owner",
      "Owner Name",
      "Landlord",
      "Owner",
      "Lessor",
    ]);

  if (landlord) fields["Landlord Name"] = landlord;

  const unit = extractByLabels(detailLines, [
    "Unit Number",
    "Premises Unit",
    "Apartment Number",
    "Apartment No",
    "House Number",
    "House No",
    "Lot No",
    "Unit",
  ]);
  const parsedUnitNumber = extractUnitNumber(unit) ?? extractUnitNumber(tenancyDetailsText(text));
  if (parsedUnitNumber) fields["Unit Number"] = parsedUnitNumber;

  const address = extractMultilineByLabels(detailLines, [
    "Property Address",
    "Premises Address",
    "Residence Address",
    "Building Address",
    "Premises Unit",
    "Property Name",
    "Residence Name",
    "Apartment Name",
    "Condominium",
    "Address",
  ]);
  if (address) fields["Property Address"] = address;

  const agreementDateValue = extractByLabels(detailLines, [
    "Agreement Date",
    "Start Date",
    "Tenancy Date",
    "Commencement Date",
    "Date",
  ]);
  const agreementDate = extractDate(agreementDateValue ?? "") ?? extractDate(text);
  if (agreementDate) fields["Agreement Date"] = agreementDate;

  const fullName = request.fullName?.trim();
  const communityName = request.communityName?.trim();
  const unitNumber = request.unitNumber?.trim();

  if (
    fullName &&
    !fields["Tenant Name"] &&
    textContains(text, fullName)
  ) {
    fields["Tenant Name"] = fullName;
  }
  if (
    unitNumber &&
    !fields["Unit Number"] &&
    textContains(text, unitNumber)
  ) {
    fields["Unit Number"] = unitNumber;
  }
  if (
    communityName &&
    !fields["Property Address"] &&
    textContains(text, communityName)
  ) {
    fields["Property Address"] = communityName;
  }
}

function extractUtilityBillFields(
  text: string,
  lines: string[],
  fields: OcrFields,
  request: VerificationRequestData,
) {
  fields["Bill Type"] = detectBillType(text);

  const amount = extractAmount(text, lines);
  if (amount) fields.Amount = amount;

  const tenant = extractByLabels(lines, [
    "Tenant Name",
    "Customer Name",
    "Account Name",
    "Registered Name",
    "Tenant",
    "Name",
  ]);
  if (tenant) fields["Tenant Name"] = tenant;

  const address = extractByLabels(lines, [
    "Property Address",
    "Premises Address",
    "Service Address",
    "Billing Address",
    "Supply Address",
    "Address",
  ]);
  if (address) fields["Property Address"] = address;

  const billDate = extractByLabels(lines, [
    "Bill Date",
    "Billing Date",
    "Invoice Date",
    "Statement Date",
    "Date",
  ]);
  if (billDate) fields["Bill Date"] = billDate;

  const fullName = request.fullName?.trim();
  const communityName = request.communityName?.trim();
  if (fullName && !fields["Tenant Name"] && textContains(text, fullName)) {
    fields["Tenant Name"] = fullName;
  }
  if (
    communityName &&
    !fields["Property Address"] &&
    textContains(text, communityName)
  ) {
    fields["Property Address"] = communityName;
  }
}

function extractAccessCardFields(
  text: string,
  lines: string[],
  fields: OcrFields,
  request: VerificationRequestData,
) {
  const address = extractByLabels(lines, [
    "Property Address",
    "Residence Address",
    "Apartment Name",
    "Condominium",
    "Apartment",
    "Building",
    "Address",
  ]);
  if (address) fields["Property Address"] = address;

  const unit = extractByLabels(lines, [
    "Unit Number",
    "Apartment Number",
    "Apartment No",
    "House Number",
    "House No",
    "Lot No",
    "Unit",
  ]) || request.unitNumber?.trim();
  if (unit && textContains(text, unit)) fields["Unit Number"] = unit;

  const cardNumber = extractByLabels(lines, [
    "Access Card Number",
    "Access Card No",
    "Resident Card Number",
    "RFID Number",
    "RFID No",
    "Card Number",
    "Card No",
    "Card ID",
  ]) || extractCardNumber(text);
  if (cardNumber) fields["Card Number"] = cardNumber;

  const communityName = request.communityName?.trim();
  if (
    communityName &&
    !fields["Property Address"] &&
    textContains(text, communityName)
  ) {
    fields["Property Address"] = communityName;
  }
}

function cleanOcrText(text: string): string {
  return text
    .replace(/\r/g, "\n")
    .split("\n")
    .map((line) => line.replace(/[ \t]+/g, " ").trim())
    .join("\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function nonEmptyLines(text: string): string[] {
  return text
    .split(/\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0);
}

function tenancyDetailsText(text: string): string {
  return text.split(/\n(?:1\.\s+Parties|2\.\s+Main Agreement Terms)\b/i)[0];
}

function extractByLabels(lines: string[], labels: string[]): string | undefined {
  const sortedLabels = [...labels].sort((a, b) => b.length - a.length);
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    for (const label of sortedLabels) {
      const escaped = escapeRegExp(label);
      const separated = new RegExp(`^${escaped}\\s*[:-]\\s*(.+)$`, "i");
      const separatedMatch = line.match(separated);
      if (separatedMatch?.[1]) {
        const value = cleanExtractedValue(separatedMatch[1]);
        if (value && !isRejectedExtractedValue(value)) return value;
      }

      const inline = new RegExp(`^${escaped}\\s+(.+)$`, "i");
      const inlineMatch = line.match(inline);
      if (inlineMatch?.[1]) {
        const value = cleanExtractedValue(inlineMatch[1]);
        if (value && !isRejectedExtractedValue(value)) return value;
      }

      const labelOnly = new RegExp(`^${escaped}\\s*[:-]?\\s*$`, "i");
      if (labelOnly.test(line)) {
        const next = nextNonEmpty(lines, i);
        if (next && !isRejectedExtractedValue(next)) return next;
      }
    }
  }
  return undefined;
}

function extractMultilineByLabels(
  lines: string[],
  labels: string[],
): string | undefined {
  const sortedLabels = [...labels].sort((a, b) => b.length - a.length);
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    for (const label of sortedLabels) {
      const escaped = escapeRegExp(label);
      const separated = new RegExp(`^${escaped}\\s*[:-]\\s*(.+)$`, "i");
      const inline = new RegExp(`^${escaped}\\s+(.+)$`, "i");
      const match = line.match(separated) ?? line.match(inline);
      const firstValue = cleanExtractedValue(match?.[1]);
      if (firstValue && !isRejectedExtractedValue(firstValue)) {
        return collectContinuation(firstValue, lines, i);
      }
    }
  }
  return undefined;
}

function collectContinuation(
  firstValue: string,
  lines: string[],
  index: number,
): string {
  const parts = [firstValue];
  for (let i = index + 1; i < lines.length && i <= index + 4; i++) {
    const value = cleanExtractedValue(lines[i]);
    if (!value || isRejectedExtractedValue(value) || startsWithKnownLabel(value)) {
      break;
    }
    parts.push(value);
  }
  return parts.join(" ").replace(/\s+/g, " ").trim();
}

function nextNonEmpty(lines: string[], index: number): string | undefined {
  for (let i = index + 1; i < lines.length && i <= index + 3; i++) {
    const value = cleanExtractedValue(lines[i]);
    if (value && !isRejectedExtractedValue(value)) return value;
  }
  return undefined;
}

function sentenceValue(text: string, pattern: RegExp): string | undefined {
  const value = cleanExtractedValue(text.match(pattern)?.[1]);
  return value && !isLabelOnly(value) && !isHeading(value) ? value : undefined;
}

function extractDate(text: string): string | undefined {
  const match = text.match(
    /\b(\d{1,2}[\/\-.]\d{1,2}[\/\-.]\d{2,4}|\d{4}[\/\-.]\d{1,2}[\/\-.]\d{1,2}|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{1,2},?\s+\d{4}|\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{4})\b/i,
  );
  return cleanExtractedValue(match?.[0]);
}

function extractAmount(text: string, lines: string[]): string | undefined {
  const amountLabels = [
    "Amount Due",
    "Total Payable",
    "Total Amount",
    "Balance Due",
    "Current Charges",
    "Amount",
  ];
  for (const label of amountLabels) {
    const value = amountFromText(extractByLabels(lines, [label]));
    if (value) return value;
  }

  const priorityWords = [
    "amount due",
    "total payable",
    "total amount",
    "balance due",
    "current charges",
  ];
  for (const word of priorityWords) {
    const line = lines.find((value) => value.toLowerCase().includes(word));
    const amount = amountFromText(line);
    if (amount) return amount;
  }

  return amountFromText(text);
}

function amountFromText(value?: string): string | undefined {
  const match = value?.match(/\b(RM|MYR)\s*([0-9][0-9,]*(?:\.\d{1,2})?)\b/i);
  if (match?.[1] && match[2]) return `${match[1].toUpperCase()} ${match[2]}`;
  return value?.match(/\b\d{1,3}(?:,\d{3})*(?:\.\d{2})\b/)?.[0];
}

function detectBillType(text: string): string {
  const normalized = text.toLowerCase().replace(/\s+/g, " ");
  if (/(electric|electricity|tnb)/.test(normalized)) return "Electricity";
  if (/(water|air selangor|syabas)/.test(normalized)) return "Water";
  if (/(internet|unifi|time fibre|maxis fibre|broadband)/.test(normalized)) {
    return "Internet";
  }
  if (/(maintenance|service charge|sinking fund)/.test(normalized)) {
    return "Maintenance";
  }
  return "Other";
}

function extractCardNumber(text: string): string | undefined {
  const prefixed = text.match(/\b(?:AC|ACD|RFID)[- ]?[A-Z0-9]{4,}\b/i)?.[0];
  if (prefixed) return prefixed.toUpperCase().replace(/\s+/g, "-");
  return text.match(/\b\d{6,}\b/)?.[0];
}

function extractUnitNumber(value?: string): string | undefined {
  if (!value) return undefined;
  return value.match(/\b(?:[A-Z]{1,3}[- ]?)?\d{1,2}-\d{1,4}(?:-\d{1,4})?\b/i)?.[0];
}

function cleanExtractedValue(value?: string): string | undefined {
  if (!value) return undefined;
  const cleaned = trimAtNextLabel(value)
    .replace(/[ \t]+/g, " ")
    .replace(/^[\s:;|]+/, "")
    .replace(/[\s,;|]+$/, "")
    .trim();
  return cleaned.length > 0 ? cleaned : undefined;
}

function trimAtNextLabel(value: string): string {
  const labels = knownLabels();
  let result = value;
  for (const label of labels) {
    const match = result.match(new RegExp(`\\s+${escapeRegExp(label)}\\s*[:-]`, "i"));
    if (match?.index !== undefined) result = result.slice(0, match.index);
  }
  return result;
}

function startsWithKnownLabel(value: string): boolean {
  return knownLabels().some((label) =>
    new RegExp(`^${escapeRegExp(label)}(?:\\s*[:-]|\\s+)`, "i").test(value),
  );
}

function knownLabels(): string[] {
  return [
    "Tenant Name",
    "Landlord Name",
    "Landlord / Owner",
    "Property Address",
    "Premises Address",
    "Premises Unit",
    "Unit Number",
    "Agreement Date",
    "Agreement Date",
    "Landlord ID",
    "Landlord Address",
    "Landlord Contact",
    "Tenant ID",
    "Tenant Current Address",
    "Tenant Contact",
    "Car Park / Access Card",
    "Tenancy Term",
    "Monthly Rent",
    "Payment Due Date",
    "Security Deposit",
    "Utility Deposit",
    "Advance Rental",
    "Permitted Use",
    "Number of Occupants",
    "Bill Date",
    "Amount Due",
    "Card Number",
    "Tenant",
    "Landlord",
    "Owner",
    "Unit",
    "Date",
  ];
}

function textContains(text: string, value: string): boolean {
  return text.toLowerCase().includes(value.toLowerCase());
}

function isLabelOnly(value: string): boolean {
  return /^(tenant|tenant name|unit|unit number|property address|address|landlord|landlord name|owner|owner name|lessor|agreement date|bill date|date|amount|card number)\s*:?\s*$/i.test(
    value.trim(),
  );
}

function isHeading(value: string): boolean {
  return /^(tenancy agreement|residential tenancy agreement|key agreement details|agreement particulars|item details|activities|parties|premises|signatures|property|number|\d+\.\s+.+)$/i.test(
    value.trim(),
  );
}

function isRejectedExtractedValue(value: string): boolean {
  return isLabelOnly(value) || isHeading(value) || startsWithKnownLabel(value);
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
