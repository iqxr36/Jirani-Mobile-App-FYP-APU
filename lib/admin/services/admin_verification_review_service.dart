import 'package:jirani/shared/services/ocr_parser_service.dart';
import 'package:jirani/shared/models/extracted_document_data.dart';
import 'package:jirani/shared/models/verification_request.dart';

class AdminVerificationReviewService {
  AdminVerificationReviewService({OcrParserService? parser})
    : _parser = parser ?? OcrParserService();

  final OcrParserService _parser;

  ExtractedDocumentData initialReviewData(VerificationRequest request) {
    final structuredData = _structuredDataFromRequest(request);
    if (structuredData != null) return structuredData;

    final documentType = documentTypeFromValue(request.documentType);
    if (documentType == DocumentType.unknown) {
      return _parser.processOcrText(request.ocrText);
    }
    return _parser.extractByDocumentType(request.ocrText, documentType);
  }

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
      DocumentType.accessCard ||
      DocumentType.otherProof ||
      DocumentType.unknown => null,
    };
  }
}
