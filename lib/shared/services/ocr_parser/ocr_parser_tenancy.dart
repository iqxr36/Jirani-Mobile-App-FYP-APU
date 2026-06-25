part of '../ocr_parser_service.dart';

mixin _OcrParserTenancyMixin on _OcrParserServiceBase {
  ExtractedDocumentData extractTenancyAgreement(String text) {
    final fullText = cleanOcrText(text);
    final detailText = _tenancyDetailsText(fullText);
    return ExtractedDocumentData(
      type: DocumentType.tenancyAgreement,
      tenantName:
          _sentenceValue(
            fullText,
            RegExp(r'\bTenant\s+Name\s+is\s+([^.\n,;]+)', caseSensitive: false),
          ) ??
          cleanExtractedValue(
            extractByLabels(detailText, _tenancyLabelsTenantName),
          ),
      unitNumber:
          _extractUnitNumber(
            extractByLabels(detailText, _tenancyLabelsUnitNumber),
          ) ??
          _extractUnitNumber(detailText),
      propertyAddress: cleanExtractedValue(
        _extractMultilineByLabels(detailText, _tenancyLabelsPropertyAddress),
      ),
      landlordName:
          _sentenceValue(
            fullText,
            RegExp(
              r'\bLandlord\s+Name\s+is\s+([^.\n,;]+)',
              caseSensitive: false,
            ),
          ) ??
          cleanExtractedValue(
            extractByLabels(detailText, _tenancyLabelsLandlordName),
          ),
      agreementDate:
          extractDate(
            extractByLabels(detailText, _tenancyLabelsAgreementDate) ?? '',
          ) ??
          extractDate(fullText),
      fullText: fullText,
    );
  }
}
