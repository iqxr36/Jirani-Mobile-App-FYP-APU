import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/utils/admin_formatters.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/core/constants/app_constants.dart';
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
              Icon(
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
              AdminStatusPill(
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
    final showFullText = fullTextOnly || structuredFields.isEmpty;
    final autoVerification = request.autoVerification;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (request.adminStatus == AppConstants.adminStatusOcrMatched ||
            autoVerification?.eligible == true) ...[
          const AdminStatusNotice(
            icon: Icons.verified_user_rounded,
            title: 'OCR matched resident details',
            body: 'Admin approval is still required before this resident becomes verified.',
          ),
          const SizedBox(height: 14),
        ],
        if (autoVerification != null &&
            autoVerification.requiresManualReview) ...[
          AdminAutoVerificationReviewPanel(result: autoVerification),
          const SizedBox(height: 14),
        ],
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
        ],
        if (showFullText) ...[
          if (structuredFields.isNotEmpty) ...[
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

  bool _usesFullTextOnly(String documentType) {
    return documentType == AppConstants.documentTypeAccessCard ||
        documentType == AppConstants.documentTypeOtherProof;
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
      DocumentType.unknown => const <String, String>{
        'resident_name': 'Resident Name',
        'unit_number': 'Unit Number',
        'property_address': 'Property Address',
        'issuer': 'Issuer',
        'document_date': 'Document Date',
        'card_number': 'Card Number',
        'summary': 'Summary',
      },
    };
  }
}

class AdminAutoVerificationReviewPanel extends StatelessWidget {
  const AdminAutoVerificationReviewPanel({super.key, required this.result});

  final AutoVerificationResult result;

  @override
  Widget build(BuildContext context) {
    final rows = _reviewRows(result.checks);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.warning.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AdminColors.warning,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Manual review required',
                  style: TextStyle(
                    color: AdminColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (result.reasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.reasons
                  .map((reason) => _AdminReviewReasonChip(reason: reason))
                  .toList(),
            ),
          ],
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rows
                  .map((row) => _AdminVerificationCheckTile(row: row))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  List<_AdminVerificationCheckRow> _reviewRows(
    Map<String, AutoVerificationCheck> checks,
  ) {
    const labels = <String, String>{
      'firstNameMatch': 'First name',
      'lastNameMatch': 'Last name',
      'unitMatch': 'Unit',
      'communityObserved': 'Community',
      'emailObserved': 'Email',
      'phoneObserved': 'Phone',
    };

    return labels.entries
        .map((entry) {
          final check = checks[entry.key];
          if (check == null) return null;
          return _AdminVerificationCheckRow(label: entry.value, check: check);
        })
        .whereType<_AdminVerificationCheckRow>()
        .toList();
  }
}

class _AdminReviewReasonChip extends StatelessWidget {
  const _AdminReviewReasonChip({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AdminColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AdminColors.danger.withValues(alpha: 0.18)),
      ),
      child: Text(
        reason,
        style: const TextStyle(
          color: AdminColors.danger,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdminVerificationCheckTile extends StatelessWidget {
  const _AdminVerificationCheckTile({required this.row});

  final _AdminVerificationCheckRow row;

  @override
  Widget build(BuildContext context) {
    final check = row.check;
    final color = _statusColor(check);
    final status = _statusLabel(check);
    final actual = check.actual.trim().isEmpty ? 'Not found' : check.actual;

    return Container(
      constraints: const BoxConstraints(minWidth: 190, maxWidth: 360),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _statusIcon(check),
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  row.label,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (check.expected.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            _AdminVerificationCheckLine(
              label: 'Submitted',
              value: check.expected,
            ),
          ],
          const SizedBox(height: 4),
          _AdminVerificationCheckLine(label: 'Document', value: actual),
        ],
      ),
    );
  }

  Color _statusColor(AutoVerificationCheck check) {
    if (check.skipped) return AdminColors.muted;
    return check.passed ? AdminColors.success : AdminColors.danger;
  }

  IconData _statusIcon(AutoVerificationCheck check) {
    if (check.skipped) return Icons.remove_circle_outline_rounded;
    return check.passed ? Icons.check_circle_rounded : Icons.cancel_rounded;
  }

  String _statusLabel(AutoVerificationCheck check) {
    if (check.skipped) return 'Not found';
    return check.passed ? 'Match' : 'Mismatch';
  }
}

class _AdminVerificationCheckLine extends StatelessWidget {
  const _AdminVerificationCheckLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: AdminColors.ink,
          fontSize: 11,
          height: 1.35,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: AdminColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AdminVerificationCheckRow {
  const _AdminVerificationCheckRow({
    required this.label,
    required this.check,
  });

  final String label;
  final AutoVerificationCheck check;
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
