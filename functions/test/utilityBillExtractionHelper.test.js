const assert = require("node:assert/strict");
const test = require("node:test");

const {
  mergeDocumentAiWithFallback,
  needsUtilityManualReview,
} = require("../lib/ocr/utilityBillExtractionHelper");

function documentAiField(value, confidence = 0.93) {
  return {value, confidence, source: "document_ai"};
}

test("water bill fixes split dates and service address", () => {
  const fullText = `
SAMPLE TEST BILL
WATER UTILITY BILL
Issued By CityWater Management Sdn Bhd TOTAL AMOUNT PAYABLE
RM 46.05
Bill Details
Utility Type Water
Billed To / Bill Holder
Name
Nur Aisyah binti Hassan
Issued By / Utility
Provider
CityWater Management Sdn Bhd
Supply Account Number WTR-18-07-660912
Statement Date 3 June 2026
Last Payment Date / Due
Date
18 June 2026
Supply / Service
Address
Unit A-18-07, Vista Harmoni Condominium, Jalan Jalil Perkasa 1, Bukit Jalil,
57000 Kuala Lumpur, Malaysia
Meter Number CW-9001178
Charges Summary
`;

  const result = mergeDocumentAiWithFallback(
    {
      account_number: documentAiField("WTR-18-07-660912"),
      bill_date: documentAiField("Last Payment Date / Due"),
      bill_holder_name: documentAiField("Nur Aisyah binti Hassan"),
      total_amount: documentAiField("RM 46.05"),
      utility_issuer_or_provider: documentAiField("CityWater Management Sdn Bhd"),
      utility_type: documentAiField("Water"),
    },
    fullText,
  );

  assert.equal(result.fields.bill_date.value, "3 June 2026");
  assert.equal(result.fields.due_date.value, "18 June 2026");
  assert.equal(
    result.fields.service_address.value,
    "Unit A-18-07, Vista Harmoni Condominium, Jalan Jalil Perkasa 1, Bukit Jalil, 57000 Kuala Lumpur, Malaysia",
  );
  assert.equal(needsUtilityManualReview(result.fields, fullText), false);
});

test("electricity bill replaces wrong provider and due-date label noise", () => {
  const fullText = `
ELECTRICITY BILL
Issued By MetroGrid Energy Sdn Bhd TOTAL AMOUNT PAYABLE
RM 209.63
Bill Details
Utility Type Electricity
Customer / Bill Holder
Name
Nur Aisyah binti Hassan
Utility Issuer / Provider MetroGrid Energy Sdn Bhd
Meter Account Number ELEC-57000-881204
Bill Issue Date 5 June 2026
Payment Due Date 25 June 2026
Premise / Service
Address
Unit A-18-07, Vista Harmoni Condominium, Jalan Jalil Perkasa 1, Bukit Jalil,
57000 Kuala Lumpur, Malaysia
`;

  const result = mergeDocumentAiWithFallback(
    {
      account_number: documentAiField("ELEC-57000-881204"),
      bill_date: documentAiField("5 June 2026"),
      bill_holder_name: documentAiField("Nur Aisyah binti Hassan"),
      due_date: documentAiField("Premise / Service"),
      total_amount: documentAiField("RM 209.63"),
      utility_issuer_or_provider: documentAiField("Unifi"),
      utility_type: documentAiField("Electricity"),
    },
    fullText,
  );

  assert.equal(result.fields.utility_issuer_or_provider.value, "MetroGrid Energy Sdn Bhd");
  assert.equal(result.fields.due_date.value, "25 June 2026");
  assert.equal(
    result.fields.service_address.value,
    "Unit A-18-07, Vista Harmoni Condominium, Jalan Jalil Perkasa 1, Bukit Jalil, 57000 Kuala Lumpur, Malaysia",
  );
});

test("internet bill fills provider and service address", () => {
  const fullText = `
INTERNET SERVICE BILL
Issued By KL FiberNet Sdn Bhd TOTAL AMOUNT PAYABLE
RM 147.34
Bill Details
Utility Type Internet
Bill Holder Name Nur Aisyah binti Hassan
Utility Issuer / Provider KL FiberNet Sdn Bhd
Account Number INT-807-553921
Bill Date 1 June 2026
Due Date 20 June 2026
Service Address Unit A-18-07, Vista Harmoni Condominium, Jalan Jalil Perkasa 1, Bukit Jalil,
57000 Kuala Lumpur, Malaysia
`;

  const result = mergeDocumentAiWithFallback(
    {
      account_number: documentAiField("INT-807-553921"),
      bill_date: documentAiField("1 June 2026"),
      bill_holder_name: documentAiField("Nur Aisyah binti Hassan"),
      due_date: documentAiField("20 June 2026"),
      total_amount: documentAiField("RM 147.34"),
      utility_type: documentAiField("Internet"),
    },
    fullText,
  );

  assert.equal(result.fields.utility_issuer_or_provider.value, "KL FiberNet Sdn Bhd");
  assert.equal(
    result.fields.service_address.value,
    "Unit A-18-07, Vista Harmoni Condominium, Jalan Jalil Perkasa 1, Bukit Jalil, 57000 Kuala Lumpur, Malaysia",
  );
});

test("monthly rent bill preserves raw type and fills provider/address", () => {
  const fullText = `
MONTHLY HOUSE RENT BILL
Issued By Ahmad bin Rahman (Landlord / Property Owner) TOTAL AMOUNT PAYABLE
RM 1,920.00
Bill Details
Utility Type Monthly House Rent
Bill Holder Name Nur Aisyah binti Hassan
Utility Issuer / Provider Ahmad bin Rahman - Landlord
Account Number RENT-A1807-202606
Bill Date 1 June 2026
Due Date 7 June 2026
Service Address Unit A-18-07, Vista Harmoni Condominium, Jalan Jalil Perkasa 1, Bukit Jalil,
57000 Kuala Lumpur, Malaysia
`;

  const result = mergeDocumentAiWithFallback(
    {
      account_number: documentAiField("RENT-A1807-202606"),
      bill_date: documentAiField("1 June 2026"),
      bill_holder_name: documentAiField("Nur Aisyah binti Hassan"),
      due_date: documentAiField("7 June 2026"),
      total_amount: documentAiField("RM 1,920.00"),
      utility_type: documentAiField("Other"),
    },
    fullText,
  );

  assert.equal(result.fields.utility_issuer_or_provider.value, "Ahmad bin Rahman - Landlord");
  assert.equal(result.fields.utility_type.value, "Monthly House Rent");
  assert.equal(
    result.fields.service_address.value,
    "Unit A-18-07, Vista Harmoni Condominium, Jalan Jalil Perkasa 1, Bukit Jalil, 57000 Kuala Lumpur, Malaysia",
  );
});
