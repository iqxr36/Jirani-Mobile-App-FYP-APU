part of '../ocr_parser_service.dart';

mixin _OcrParserDetectionMixin on _OcrParserServiceBase {
  DocumentType detectDocumentType(String text) {
    final searchText = normalizeForSearch(text);
    if (searchText.isEmpty) return DocumentType.otherProof;

    if (_containsAny(searchText, const [
      'tenancy agreement',
      'residential tenancy agreement',
      'rental agreement',
    ])) {
      return DocumentType.tenancyAgreement;
    }

    final hasTenantCue = _containsAny(searchText, const ['tenant', 'lessee']);
    final hasLandlordCue = _containsAny(searchText, const [
      'landlord',
      'lessor',
    ]);
    final hasPremisesCue = searchText.contains('premises');
    if (hasTenantCue && (hasLandlordCue || hasPremisesCue)) {
      return DocumentType.tenancyAgreement;
    }

    if (_containsAny(searchText, const [
      'access card',
      'card number',
      'card no',
      'card id',
      'rfid',
      'resident card',
      'proximity card',
      'lift & door access',
      'lift and door access',
    ])) {
      return DocumentType.accessCard;
    }
    if (searchText.contains('access') &&
        _containsAny(searchText, const ['lift', 'door', 'issued by'])) {
      return DocumentType.accessCard;
    }

    final utilityScore = _keywordScore(searchText, const [
      'electric',
      'electricity',
      'tnb',
      'water',
      'air selangor',
      'internet',
      'unifi',
      'time fibre',
      'maxis fibre',
      'amount due',
      'total amount',
      'total payable',
      'bill',
      'invoice',
      'account number',
    ]);
    final hasUtilityService = _containsAny(searchText, const [
      'electric',
      'electricity',
      'tnb',
      'water',
      'air selangor',
      'internet',
      'unifi',
      'time fibre',
      'maxis fibre',
    ]);
    final hasBillCue = _containsAny(searchText, const [
      'amount due',
      'total amount',
      'total payable',
      'bill',
      'invoice',
      'account number',
    ]);
    if (utilityScore >= 2 || (hasUtilityService && hasBillCue)) {
      return DocumentType.utilityBill;
    }

    return DocumentType.otherProof;
  }
}
