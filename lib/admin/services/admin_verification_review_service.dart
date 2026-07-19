// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_verification_review_service.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Tuesday,16-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:jirani/shared/models/extracted_document_data.dart';
import 'package:jirani/shared/models/verification_request.dart';

// Admin verification OCR feature: prepares extracted document data for the admin review UI.
class AdminVerificationReviewService {
  const AdminVerificationReviewService();

  // Admin verification OCR feature: returns structured OCR fields when available or falls back to raw OCR text.
  ExtractedDocumentData initialReviewData(VerificationRequest request) {
    final structuredData = _structuredDataFromRequest(request);
    if (structuredData != null) return structuredData;

    final documentType = documentTypeFromValue(request.documentType);
    return ExtractedDocumentData(
      type: documentType == DocumentType.unknown
          ? DocumentType.otherProof
          : documentType,
      fullText: request.ocrText,
    );
  }

  // Admin verification OCR feature: maps stored OCR fields into the typed review form model.
  ExtractedDocumentData? _structuredDataFromRequest(
    VerificationRequest request,
  ) {
    final fields = request.extractedFields;
    if (fields.isEmpty) return null;
    final documentType = documentTypeFromValue(request.documentType);

    String? value(String key) {
      final trimmed = fields[key]?.value.trim() ?? '';
      return trimmed.isEmpty ? null : trimmed;
    }

    String? firstValue(List<String> keys) {
      for (final key in keys) {
        final fieldValue = value(key);
        if (fieldValue != null) return fieldValue;
      }
      return null;
    }

    return switch (documentType) {
      DocumentType.tenancyAgreement => ExtractedDocumentData(
        type: DocumentType.tenancyAgreement,
        tenantName: value('tenant_name'),
        landlordName: value('landlord_name'),
        propertyAddress: value('property_address'),
        unitNumber: value('unit_number'),
        agreementDate: value('agreement_date'),
        fullText: request.ocrText,
      ),
      DocumentType.utilityBill => ExtractedDocumentData(
        type: DocumentType.utilityBill,
        tenantName: firstValue(['bill_holder_name', 'tenant_name']),
        propertyAddress: firstValue(['service_address', 'property_address']),
        billType: firstValue(['utility_type', 'bill_type']),
        amount: firstValue(['total_amount', 'amount']),
        billDate: value('bill_date'),
        accountNumber: value('account_number'),
        billHolderName: firstValue(['bill_holder_name', 'tenant_name']),
        dueDate: value('due_date'),
        serviceAddress: firstValue(['service_address', 'property_address']),
        totalAmount: firstValue(['total_amount', 'amount']),
        utilityProvider: firstValue([
          'utility_issuer_or_provider',
          'utility_provider',
        ]),
        utilityType: firstValue(['utility_type', 'bill_type']),
        fullText: request.ocrText,
      ),
      DocumentType.accessCard => ExtractedDocumentData(
        type: DocumentType.accessCard,
        residentName: firstValue(['resident_name', 'tenant_name']),
        tenantName: firstValue(['resident_name', 'tenant_name']),
        propertyAddress: value('property_address'),
        unitNumber: value('unit_number'),
        issuer: value('issuer'),
        documentDate: value('document_date'),
        cardNumber: value('card_number'),
        summary: value('summary'),
        fullText: request.ocrText,
      ),
      DocumentType.otherProof || DocumentType.unknown => ExtractedDocumentData(
        type: DocumentType.otherProof,
        residentName: firstValue(['resident_name', 'tenant_name']),
        tenantName: firstValue(['resident_name', 'tenant_name']),
        propertyAddress: value('property_address'),
        unitNumber: value('unit_number'),
        issuer: value('issuer'),
        documentDate: value('document_date'),
        cardNumber: value('card_number'),
        summary: value('summary'),
        fullText: request.ocrText,
      ),
    };
  }
}
