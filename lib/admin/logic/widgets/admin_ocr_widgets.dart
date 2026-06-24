import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/utils/admin_formatters.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/services/ocr_parser_service.dart';
import 'package:jirani/shared/models/extracted_document_data.dart';
import 'package:jirani/shared/models/verification_request.dart';

class AdminExtractedTextPanel extends StatelessWidget {
  const AdminExtractedTextPanel({super.key, required this.request});

  final VerificationRequest request;

  @override
  Widget build(BuildContext context) {
    final status = request.ocrStatus.trim();
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.text_snippet_rounded,
                color: AdminColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  adminDocumentTypeLabel(request.documentType),
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const AdminStatusPill(
                label: 'Text extraction',
                color: AdminColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          switch (status) {
            AppConstants.ocrStatusPending => const AdminOcrStatusView(
              icon: Icons.schedule_rounded,
              message: 'OCR queued. Waiting for backend processing.',
            ),
            AppConstants.ocrStatusProcessing => const AdminOcrStatusView(
              icon: Icons.sync_rounded,
              message: 'OCR is processing this document.',
              showProgress: true,
            ),
            AppConstants.ocrStatusCompleted => AdminOcrResultView(
              request: request,
            ),
            AppConstants.ocrStatusFailed => AdminOcrStatusView(
              icon: Icons.info_outline_rounded,
              message: request.ocrError?.trim().isNotEmpty == true
                  ? request.ocrError!
                  : 'OCR failed. Open the document and review it manually.',
            ),
            _ => const AdminOcrStatusView(
              icon: Icons.hourglass_empty_rounded,
              message: 'OCR has not started for this request yet.',
            ),
          },
        ],
      ),
    );
  }
}

class AdminOcrStatusView extends StatelessWidget {
  const AdminOcrStatusView({
    super.key,
    required this.icon,
    required this.message,
    this.showProgress = false,
  });

  final IconData icon;
  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress)
              const CircularProgressIndicator(strokeWidth: 2)
            else
              Icon(icon, color: AdminColors.muted, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AdminColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminOcrResultView extends StatelessWidget {
  const AdminOcrResultView({super.key, required this.request});

  final VerificationRequest request;

  @override
  Widget build(BuildContext context) {
    final text = request.ocrText.trim();
    final fullTextOnly = _usesFullTextOnly(request.documentType);
    final structuredFields = _structuredFieldEntries(request);
    final Map<String, String> parsedFields;
    final bool showParsedConfidence;
    if (structuredFields.isNotEmpty) {
      parsedFields = const <String, String>{};
      showParsedConfidence = false;
    } else if (fullTextOnly) {
      parsedFields = const <String, String>{};
      showParsedConfidence = false;
    } else if (_shouldParseDisplayFields(request)) {
      parsedFields = _parseDisplayFields(request);
      showParsedConfidence = true;
    } else {
      parsedFields = request.ocrFields;
      showParsedConfidence = false;
    }
    final visibleFields = Map<String, String>.from(parsedFields)
      ..remove('type')
      ..remove('fullText');
    final showFullText =
        fullTextOnly || (visibleFields.isEmpty && structuredFields.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (structuredFields.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: structuredFields
                .map(
                  (e) => AdminOcrFieldChip(
                    label: e.label,
                    value: e.field.value,
                    confidence: e.field.confidence,
                    highlight: e.field.confidence < 0.75,
                  ),
                )
                .toList(),
          ),
        ] else if (visibleFields.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visibleFields.entries
                .map(
                  (e) => AdminOcrFieldChip(
                    label: e.key,
                    value: e.value,
                    confidence: showParsedConfidence
                        ? _parsedFieldConfidence(request.documentType)
                        : null,
                  ),
                )
                .toList(),
          ),
        ],
        if (showFullText) ...[
          if (visibleFields.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: AdminColors.border),
            const SizedBox(height: 12),
          ],
          const Text(
            'FULL EXTRACTED TEXT',
            style: TextStyle(
              color: AdminColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AdminColors.border),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                text.isEmpty ? 'No text was saved by OCR.' : text,
                style: const TextStyle(
                  color: AdminColors.ink,
                  fontSize: 13,
                  height: 1.65,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _shouldParseDisplayFields(VerificationRequest request) {
    if (request.ocrText.trim().isEmpty) return false;
    return request.documentType == AppConstants.documentTypeTenancyAgreement ||
        request.documentType == AppConstants.documentTypeUtilityBill;
  }

  bool _usesFullTextOnly(String documentType) {
    return documentType == AppConstants.documentTypeAccessCard ||
        documentType == AppConstants.documentTypeOtherProof;
  }

  Map<String, String> _parseDisplayFields(VerificationRequest request) {
    final text = request.ocrText.trim();
    if (text.isEmpty) return const {};
    final parser = OcrParserService();
    final parsed = switch (request.documentType) {
      AppConstants.documentTypeTenancyAgreement =>
        parser.extractTenancyAgreement(text),
      AppConstants.documentTypeUtilityBill => parser.extractUtilityBill(text),
      AppConstants.documentTypeOtherProof => parser.extractOtherProof(text),
      _ => parser.processOcrText(text),
    };
    return parsed.toFieldMap();
  }

  double? _parsedFieldConfidence(String documentType) {
    return switch (documentTypeFromValue(documentType)) {
      DocumentType.tenancyAgreement || DocumentType.utilityBill => 1.0,
      DocumentType.accessCard ||
      DocumentType.otherProof ||
      DocumentType.unknown => null,
    };
  }

  List<AdminStructuredFieldEntry> _structuredFieldEntries(
    VerificationRequest request,
  ) {
    final labels = _structuredFieldLabels(request.documentType);
    return labels.entries
        .map((entry) {
          final field = request.extractedFields[entry.key];
          if (field == null || field.value.trim().isEmpty) return null;
          return AdminStructuredFieldEntry(label: entry.value, field: field);
        })
        .whereType<AdminStructuredFieldEntry>()
        .toList();
  }

  Map<String, String> _structuredFieldLabels(String documentType) {
    return switch (documentTypeFromValue(documentType)) {
      DocumentType.tenancyAgreement => const <String, String>{
        'tenant_name': 'Tenant Name',
        'landlord_name': 'Landlord/Owner Name',
        'unit_number': 'Unit Number',
        'agreement_date': 'Agreement Date',
        'property_address': 'Property Address',
      },
      DocumentType.utilityBill => const <String, String>{
        'account_number': 'Account Number',
        'bill_date': 'Bill Date',
        'bill_holder_name': 'Bill Holder Name',
        'due_date': 'Due Date',
        'service_address': 'Service Address',
        'total_amount': 'Total Amount',
        'utility_issuer_or_provider': 'Utility Provider',
        'utility_type': 'Utility Type',
      },
      DocumentType.accessCard ||
      DocumentType.otherProof ||
      DocumentType.unknown => const <String, String>{},
    };
  }
}

class AdminOcrFieldChip extends StatelessWidget {
  const AdminOcrFieldChip({
    super.key,
    required this.label,
    required this.value,
    this.confidence,
    this.highlight = false,
  });

  final String label;
  final String value;
  final double? confidence;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AdminColors.warning : AdminColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${adminOcrFieldLabel(label)}: ',
                style: const TextStyle(
                  color: AdminColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AdminColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (confidence != null) ...[
            const SizedBox(height: 3),
            Text(
              'Confidence ${(confidence! * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: AdminColors.muted,
                fontSize: 11,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AdminStructuredFieldEntry {
  const AdminStructuredFieldEntry({required this.label, required this.field});

  final String label;
  final ExtractedVerificationField field;
}
