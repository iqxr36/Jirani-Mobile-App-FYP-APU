part of '../ocr_parser_service.dart';

abstract class _OcrParserServiceBase {
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

  String? _sentenceValue(String text, RegExp pattern) {
    final value = cleanExtractedValue(pattern.firstMatch(text)?.group(1));
    return value == null || _looksLikeOnlyALabel(value) ? null : value;
  }

  String _tenancyDetailsText(String text) {
    return text
        .split(RegExp(r'\n(?:1\.\s+Parties|2\.\s+Main Agreement Terms)\b'))
        .first;
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
