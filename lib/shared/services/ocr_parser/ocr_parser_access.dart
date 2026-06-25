part of '../ocr_parser_service.dart';

mixin _OcrParserAccessMixin on _OcrParserServiceBase {
  ExtractedDocumentData extractAccessCard(String text) {
    final fullText = cleanOcrText(text);
    return ExtractedDocumentData(
      type: DocumentType.accessCard,
      fullText: fullText,
    );
  }

  ExtractedDocumentData extractOtherProof(String text) {
    return ExtractedDocumentData(
      type: DocumentType.otherProof,
      fullText: cleanOcrText(text),
    );
  }
}
