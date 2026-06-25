library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:jirani/shared/models/extracted_document_data.dart';

part 'ocr_parser/ocr_parser_labels.dart';
part 'ocr_parser/ocr_parser_core.dart';
part 'ocr_parser/ocr_parser_detection.dart';
part 'ocr_parser/ocr_parser_tenancy.dart';
part 'ocr_parser/ocr_parser_utility.dart';
part 'ocr_parser/ocr_parser_access.dart';

class OcrParserService extends _OcrParserServiceBase
    with
        _OcrParserDetectionMixin,
        _OcrParserTenancyMixin,
        _OcrParserUtilityMixin,
        _OcrParserAccessMixin {
  ExtractedDocumentData processOcrText(String rawText) {
    final cleanedText = cleanOcrText(rawText);
    final type = detectDocumentType(cleanedText);
    final parsed = extractByDocumentType(cleanedText, type);

    debugPrint(
      '[OcrParserService] detected document type: ${parsed.type.name}',
    );
    debugPrint('[OcrParserService] extracted fields: ${parsed.toMap()}');
    return parsed;
  }

  ExtractedDocumentData extractByDocumentType(
    String rawText,
    DocumentType type,
  ) {
    final cleanedText = cleanOcrText(rawText);
    final parsed = switch (type) {
      DocumentType.tenancyAgreement => extractTenancyAgreement(cleanedText),
      DocumentType.utilityBill => extractUtilityBill(cleanedText),
      DocumentType.accessCard => extractAccessCard(cleanedText),
      DocumentType.otherProof ||
      DocumentType.unknown => extractOtherProof(cleanedText),
    };
    return parsed;
  }
}
