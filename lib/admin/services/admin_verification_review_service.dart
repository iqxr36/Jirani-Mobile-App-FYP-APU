import 'package:jirani/services/ocr_parser_service.dart';
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

    String? value(String key) {
      final trimmed = fields[key]?.value.trim() ?? '';
      return trimmed.isEmpty ? null : trimmed;
    }

    return ExtractedDocumentData(
      type: DocumentType.tenancyAgreement,
      tenantName: value('tenant_name'),
      landlordName: value('landlord_name'),
      propertyAddress: value('property_address'),
      unitNumber: value('unit_number'),
      agreementDate: value('agreement_date'),
      fullText: request.ocrText,
    );
  }
}
