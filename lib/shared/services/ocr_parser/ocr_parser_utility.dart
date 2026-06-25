part of '../ocr_parser_service.dart';

mixin _OcrParserUtilityMixin on _OcrParserServiceBase {
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
}
