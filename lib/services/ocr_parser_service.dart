import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:jirani/shared/models/extracted_document_data.dart';

class OcrParserService {
  static const _tenancyLabelsTenantName = [
    'Tenant',
    'Tenant Name',
    'Name of Tenant',
    'Resident Name',
    'Occupant Name',
    'Lessee',
  ];

  static const _tenancyLabelsUnitNumber = [
    'Unit',
    'Unit Number',
    'Premises Unit',
    'Apartment No',
    'Apartment Number',
    'House No',
    'House Number',
    'Lot No',
  ];

  static const _tenancyLabelsPropertyAddress = [
    'Address',
    'Property Address',
    'Premises Address',
    'Residence Address',
    'Building Address',
    'Premises Unit',
    'Property Name',
    'Residence Name',
    'Condominium',
    'Apartment Name',
  ];

  static const _tenancyLabelsLandlordName = [
    'Landlord',
    'Landlord Name',
    'Landlord / Owner',
    'Owner',
    'Owner Name',
    'Lessor',
  ];

  static const _tenancyLabelsAgreementDate = [
    'Date',
    'Agreement Date',
    'Start Date',
    'Tenancy Date',
    'Commencement Date',
  ];

  static const _utilityLabelsTenantName = [
    'Bill Holder Name',
    'Bill Holder',
    'Tenant',
    'Tenant Name',
    'Customer Name',
    'Account Name',
    'Name',
    'Registered Name',
  ];

  static const _utilityLabelsAccountNumber = [
    'Account Number',
    'Account No',
    'Account',
    'Customer Number',
    'Customer No',
    'Contract Account',
  ];

  static const _utilityLabelsPropertyAddress = [
    'Service Address',
    'Property Address',
    'Premises Address',
    'Billing Address',
    'Supply Address',
    'Address',
  ];

  static const _utilityLabelsBillDate = [
    'Bill Date',
    'Billing Date',
    'Invoice Date',
    'Statement Date',
    'Date',
  ];

  static const _utilityLabelsDueDate = [
    'Due Date',
    'Payment Due Date',
    'Pay By Date',
    'Pay Before',
  ];

  static const _utilityLabelsProvider = [
    'Utility Provider',
    'Utility Issuer or Provider',
    'Provider',
    'Issuer',
    'Supplier',
    'Company',
  ];

  static const _utilityLabelsType = [
    'Utility Type',
    'Bill Type',
    'Service Type',
    'Type',
  ];

  static const _amountLabels = [
    'Amount Due',
    'Total Amount',
    'Total Payable',
    'Balance Due',
    'Current Charges',
    'Amount',
  ];

  static const _accessLabelsPropertyAddress = [
    'Property Address',
    'Residence Address',
    'Building',
    'Condominium',
    'Apartment',
    'Apartment Name',
    'Address',
  ];

  static const _accessLabelsUnitNumber = [
    'Unit',
    'Unit Number',
    'Apartment No',
    'Apartment Number',
    'House No',
    'House Number',
    'Lot No',
  ];

  static const _accessLabelsCardNumber = [
    'Card Number',
    'Card No',
    'Card ID',
    'Access Card Number',
    'Access Card No',
    'RFID Number',
    'RFID No',
    'Resident Card Number',
  ];

  static const _allLabels = [
    ..._tenancyLabelsTenantName,
    ..._tenancyLabelsUnitNumber,
    ..._tenancyLabelsPropertyAddress,
    ..._tenancyLabelsLandlordName,
    ..._tenancyLabelsAgreementDate,
    ..._utilityLabelsTenantName,
    ..._utilityLabelsAccountNumber,
    ..._utilityLabelsPropertyAddress,
    ..._utilityLabelsBillDate,
    ..._utilityLabelsDueDate,
    ..._utilityLabelsProvider,
    ..._utilityLabelsType,
    ..._amountLabels,
    ..._accessLabelsPropertyAddress,
    ..._accessLabelsUnitNumber,
    ..._accessLabelsCardNumber,
    'Landlord / Owner',
    'Landlord ID',
    'Landlord Address',
    'Landlord Contact',
    'Tenant ID',
    'Tenant Current Address',
    'Tenant Contact',
    'Car Park / Access Card',
    'Tenancy Term',
    'Monthly Rent',
    'Payment Due Date',
    'Security Deposit',
    'Utility Deposit',
    'Advance Rental',
    'Permitted Use',
    'Number of Occupants',
    'Bill Type',
    'Type',
  ];

  String cleanOcrText(String text) {
    final normalizedBreaks = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final cleanedLines = normalizedBreaks
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
        .toList();
    return cleanedLines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  String normalizeForSearch(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

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

  String? extractByLabels(String text, List<String> labels) {
    final cleanedText = cleanOcrText(text);
    if (cleanedText.isEmpty) return null;

    final lines = cleanedText.split('\n');
    final sortedLabels = labels.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      for (final label in sortedLabels) {
        final escaped = RegExp.escape(label);
        final separatedPattern = RegExp(
          '^$escaped\\s*[:-]\\s*(.*)\$',
          caseSensitive: false,
        );
        final separatedMatch = separatedPattern.firstMatch(line);
        if (separatedMatch != null) {
          final value = cleanExtractedValue(separatedMatch.group(1));
          if (value != null && !_isRejectedExtractedValue(value)) return value;
          final next = _nextLineValue(lines, i);
          if (next != null) return next;
        }

        final inlinePattern = RegExp(
          '^$escaped\\s+(.+)\$',
          caseSensitive: false,
        );
        final inlineMatch = inlinePattern.firstMatch(line);
        if (inlineMatch != null) {
          final value = cleanExtractedValue(inlineMatch.group(1));
          if (value != null && !_isRejectedExtractedValue(value)) return value;
        }

        final labelOnlyPattern = RegExp(
          '^$escaped\\s*[:-]?\\s*\$',
          caseSensitive: false,
        );
        if (labelOnlyPattern.hasMatch(line)) {
          final next = _nextLineValue(lines, i);
          if (next != null) return next;
        }
      }
    }

    return null;
  }

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

  ExtractedDocumentData extractUtilityBill(String text) {
    final fullText = cleanOcrText(text);
    final accountNumber = cleanExtractedValue(
      extractByLabels(fullText, _utilityLabelsAccountNumber),
    );
    final tenantName = cleanExtractedValue(
      extractByLabels(fullText, _utilityLabelsTenantName),
    );
    final propertyAddress = cleanExtractedValue(
      _extractMultilineByLabels(fullText, _utilityLabelsPropertyAddress),
    );
    final amount = extractAmount(fullText);
    final billType = cleanExtractedValue(
      extractByLabels(fullText, _utilityLabelsType),
    );
    final detectedUtilityType = detectBillType('${billType ?? ''}\n$fullText');
    final billDate =
        cleanExtractedValue(
          extractByLabels(fullText, _utilityLabelsBillDate),
        ) ??
        extractDate(fullText);
    final dueDate =
        cleanExtractedValue(extractByLabels(fullText, _utilityLabelsDueDate)) ??
        _extractDueDate(fullText);
    final utilityProvider =
        cleanExtractedValue(
          extractByLabels(fullText, _utilityLabelsProvider),
        ) ??
        detectUtilityProvider(fullText);

    return ExtractedDocumentData(
      type: DocumentType.utilityBill,
      billType: detectedUtilityType,
      amount: amount,
      tenantName: tenantName,
      propertyAddress: propertyAddress,
      billDate: billDate,
      accountNumber: accountNumber ?? _extractAccountNumber(fullText),
      billHolderName: tenantName,
      dueDate: dueDate,
      serviceAddress: propertyAddress,
      totalAmount: amount,
      utilityProvider: utilityProvider,
      utilityType: detectedUtilityType,
      fullText: fullText,
    );
  }

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

  String? extractDate(String text) {
    final patterns = [
      RegExp(r'\b\d{1,2}[\/\-.]\d{1,2}[\/\-.]\d{2,4}\b'),
      RegExp(r'\b\d{4}[\/\-.]\d{1,2}[\/\-.]\d{1,2}\b'),
      RegExp(
        r'\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{1,2},?\s+\d{4}\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{4}\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      final value = cleanExtractedValue(match?.group(0));
      if (value != null) return value;
    }
    return null;
  }

  String? extractAmount(String text) {
    final cleanedText = cleanOcrText(text);
    for (final label in _amountLabels) {
      final labelledValue = extractByLabels(cleanedText, [label]);
      final amount = _extractAmountValue(labelledValue);
      if (amount != null) return amount;
    }

    final lines = cleanedText.split('\n');
    const priorityKeywords = [
      'amount due',
      'total payable',
      'total amount',
      'balance due',
      'current charges',
    ];
    for (final keyword in priorityKeywords) {
      for (final line in lines) {
        if (normalizeForSearch(line).contains(keyword)) {
          final amount = _extractAmountValue(line);
          if (amount != null) return amount;
        }
      }
    }

    final flattened = cleanedText.replaceAll('\n', ' ');
    for (final keyword in priorityKeywords) {
      final priorityPattern = RegExp(
        RegExp.escape(keyword),
        caseSensitive: false,
      );
      for (final match in priorityPattern.allMatches(flattened)) {
        final start = math.max(0, match.start - 40);
        final end = math.min(flattened.length, match.end + 100);
        final amount = _extractAmountValue(flattened.substring(start, end));
        if (amount != null) return amount;
      }
    }

    return _extractAmountValue(cleanedText);
  }

  String? _extractAccountNumber(String text) {
    final match = RegExp(
      r'\b(?:account|acct|customer|contract)\s*(?:number|no\.?|account)?\s*[:#-]?\s*([A-Z0-9][A-Z0-9 -]{4,})\b',
      caseSensitive: false,
    ).firstMatch(text);
    return cleanExtractedValue(match?.group(1));
  }

  String? _extractDueDate(String text) {
    final flattened = cleanOcrText(text).replaceAll('\n', ' ');
    final match = RegExp(
      r'\b(?:due date|payment due date|pay by|pay before)\s*[:#-]?\s*([A-Za-z]{3,9}\.?\s+\d{1,2},?\s+\d{4}|\d{1,2}\s+[A-Za-z]{3,9}\.?\s+\d{4}|\d{1,2}[\/\-.]\d{1,2}[\/\-.]\d{2,4}|\d{4}[\/\-.]\d{1,2}[\/\-.]\d{1,2})\b',
      caseSensitive: false,
    ).firstMatch(flattened);
    return cleanExtractedValue(match?.group(1));
  }

  String detectBillType(String text) {
    final labelled = extractByLabels(text, const ['Bill Type', 'Type']);
    final searchText = normalizeForSearch('${labelled ?? ''} $text');

    if (_containsAny(searchText, const ['electric', 'electricity', 'tnb'])) {
      return 'Electricity';
    }
    if (_containsAny(searchText, const ['water', 'air selangor', 'syabas'])) {
      return 'Water';
    }
    if (_containsAny(searchText, const [
      'internet',
      'unifi',
      'time fibre',
      'maxis fibre',
      'broadband',
    ])) {
      return 'Internet';
    }
    if (_containsAny(searchText, const [
      'maintenance',
      'service charge',
      'sinking fund',
    ])) {
      return 'Maintenance';
    }
    return 'Other';
  }

  String? detectUtilityProvider(String text) {
    final searchText = normalizeForSearch(text);
    if (_containsAny(searchText, const ['tenaga nasional', 'tnb'])) {
      return 'TNB';
    }
    if (_containsAny(searchText, const ['air selangor', 'syabas'])) {
      return 'Air Selangor';
    }
    if (_containsAny(searchText, const ['unifi', 'telekom malaysia', 'tm'])) {
      return 'Unifi';
    }
    if (_containsAny(searchText, const ['time fibre', 'time dotcom'])) {
      return 'TIME';
    }
    if (_containsAny(searchText, const ['maxis fibre', 'maxis'])) {
      return 'Maxis';
    }
    return null;
  }

  String? cleanExtractedValue(String? value) {
    if (value == null) return null;
    var cleaned = value
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\s+\n'), '\n')
        .trim();
    cleaned = _trimAtNextInlineLabel(cleaned);
    cleaned = cleaned.replaceAll(RegExp(r'^[\s:;|]+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[\s,;|]+$'), '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  String? _sentenceValue(String text, RegExp pattern) {
    final value = cleanExtractedValue(pattern.firstMatch(text)?.group(1));
    return value == null || _looksLikeOnlyALabel(value) ? null : value;
  }

  String _tenancyDetailsText(String text) {
    return text
        .split(RegExp(r'\n(?:1\.\s+Parties|2\.\s+Main Agreement Terms)\b'))
        .first;
  }

  String? _extractAmountValue(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final currencyMatch = RegExp(
      r'\b(RM|MYR)\s*([0-9][0-9,]*(?:\.\d{1,2})?)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (currencyMatch != null) {
      return '${currencyMatch.group(1)!.toUpperCase()} ${currencyMatch.group(2)}';
    }

    final numericMatch = RegExp(
      r'\b\d{1,3}(?:,\d{3})*(?:\.\d{2})\b',
    ).firstMatch(text);
    return numericMatch?.group(0);
  }

  String? _extractUnitNumber(String? value) {
    if (value == null) return null;
    final rawMatch = RegExp(
      r'\b(?:[A-Z]{1,3}[- ]?)?\d{1,2}-\d{1,4}(?:-\d{1,4})?\b',
      caseSensitive: false,
    ).firstMatch(value)?.group(0);
    if (rawMatch != null) return cleanExtractedValue(rawMatch);

    final cleaned = cleanExtractedValue(value);
    if (cleaned == null) return null;
    return RegExp(
      r'\b(?:[A-Z]{1,3}[- ]?)?\d{1,2}-\d{1,4}(?:-\d{1,4})?\b',
      caseSensitive: false,
    ).firstMatch(cleaned)?.group(0);
  }

  String? _nextLineValue(List<String> lines, int currentIndex) {
    for (
      var i = currentIndex + 1;
      i < lines.length && i <= currentIndex + 3;
      i++
    ) {
      final value = cleanExtractedValue(lines[i]);
      if (value != null && !_isRejectedExtractedValue(value)) return value;
    }
    return null;
  }

  String _trimAtNextInlineLabel(String value) {
    var trimmed = value;
    for (final label in _allLabels.toSet()) {
      final pattern = RegExp(
        '\\s+${RegExp.escape(label)}\\s*[:-]',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(trimmed);
      if (match != null) {
        trimmed = trimmed.substring(0, match.start).trim();
      }
    }
    return trimmed;
  }

  String? _extractMultilineByLabels(String text, List<String> labels) {
    final cleanedText = cleanOcrText(text);
    if (cleanedText.isEmpty) return null;
    final lines = cleanedText.split('\n');
    final sortedLabels = labels.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      for (final label in sortedLabels) {
        final escaped = RegExp.escape(label);
        final match =
            RegExp(
              '^$escaped\\s*[:-]\\s*(.+)\$',
              caseSensitive: false,
            ).firstMatch(line) ??
            RegExp(
              '^$escaped\\s+(.+)\$',
              caseSensitive: false,
            ).firstMatch(line);
        final firstValue = cleanExtractedValue(match?.group(1));
        if (firstValue != null && !_isRejectedExtractedValue(firstValue)) {
          return _collectContinuation(firstValue, lines, i);
        }
      }
    }
    return null;
  }

  String _collectContinuation(
    String firstValue,
    List<String> lines,
    int index,
  ) {
    final parts = [firstValue];
    for (var i = index + 1; i < lines.length && i <= index + 4; i++) {
      final value = cleanExtractedValue(lines[i]);
      if (value == null ||
          _isRejectedExtractedValue(value) ||
          _startsWithKnownLabel(value)) {
        break;
      }
      parts.add(value);
    }
    return parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _startsWithKnownLabel(String value) {
    return _allLabels.any((label) {
      return RegExp(
        '^${RegExp.escape(label)}(?:\\s*[:-]|\\s+)',
        caseSensitive: false,
      ).hasMatch(value);
    });
  }

  bool _looksLikeOnlyALabel(String value) {
    final normalized = normalizeForSearch(
      value.replaceAll(RegExp(r'[:-]+$'), ''),
    );
    return _allLabels.any((label) => normalizeForSearch(label) == normalized);
  }

  bool _isRejectedExtractedValue(String value) {
    final normalized = normalizeForSearch(value);
    if (_looksLikeOnlyALabel(value)) return true;
    if (_startsWithKnownLabel(value)) return true;
    if (normalized.length < 2) return true;
    return {
      'tenancy agreement',
      'residential tenancy agreement',
      'key agreement details',
      'agreement particulars',
      'item details',
      'activities',
      'parties',
      'premises',
      'signatures',
      'property',
      'number',
    }.contains(normalized);
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  int _keywordScore(String text, List<String> keywords) {
    return keywords.where((keyword) => text.contains(keyword)).length;
  }
}
