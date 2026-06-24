import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/models/admin_display_rows.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/admin/providers/admin_provider.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/report_model.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

enum _ReportInboxFilter { open, completed }

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String? _selectedReportId;
  _ReportInboxFilter _inboxFilter = _ReportInboxFilter.open;
  final ScrollController _detailScrollController = ScrollController();
  final ScrollController _inboxScrollController = ScrollController();

  void _setInboxFilter(_ReportInboxFilter filter) {
    if (_inboxFilter == filter) return;
    setState(() {
      _inboxFilter = filter;
      _selectedReportId = null;
    });
  }

  bool _isOpenReport(ReportModel report) {
    final status = report.status.trim();
    return status.isEmpty ||
        status == AppConstants.reportStatusOpen ||
        status == AppConstants.reportStatusUnderReview;
  }

  bool _isCompletedReport(ReportModel report) {
    final status = report.status.trim();
    return status == AppConstants.reportStatusResolved ||
        status == AppConstants.reportStatusDismissed;
  }

  List<ReportModel> _filteredReports(List<ReportModel> reports) {
    return reports.where((report) {
      return switch (_inboxFilter) {
        _ReportInboxFilter.open => _isOpenReport(report),
        _ReportInboxFilter.completed => _isCompletedReport(report),
      };
    }).toList();
  }

  @override
  void dispose() {
    _detailScrollController.dispose();
    _inboxScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final reports = adminProvider.reports;
    final filteredReports = _filteredReports(reports);
    final selectedReport = _selectedReport(filteredReports);
    final selected = selectedReport == null
        ? null
        : adminReportRowFromReport(selectedReport);
    final selectedRequest = selectedReport == null
        ? null
        : _relatedBorrowRequest(adminProvider.borrowRequests, selectedReport);
    return AdminPageScroll(
      children: [
        AdminControlBar(
          title: 'Reports and Complaints',
          subtitle:
              'Inbox-style triage for disputes, misuse, damaged items, and evidence.',
          controls: [
            const AdminFilterChipButton(label: 'Priority'),
            AdminFilterChipButton(
              label: 'Open',
              selected: _inboxFilter == _ReportInboxFilter.open,
              onPressed: () => _setInboxFilter(_ReportInboxFilter.open),
            ),
            AdminFilterChipButton(
              label: 'Completed',
              selected: _inboxFilter == _ReportInboxFilter.completed,
              onPressed: () => _setInboxFilter(_ReportInboxFilter.completed),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (reports.isEmpty)
          const AdminPanel(
            title: 'Report Inbox',
            child: AdminEmptyPanelMessage(
              icon: Icons.report_problem_rounded,
              title: 'No reports found',
              body: 'Resident complaints and report tickets will appear here.',
            ),
          )
        else if (filteredReports.isEmpty)
          AdminPanel(
            title: 'Report Inbox',
            child: AdminEmptyPanelMessage(
              icon: _inboxFilter == _ReportInboxFilter.open
                  ? Icons.inbox_rounded
                  : Icons.task_alt_rounded,
              title: _inboxFilter == _ReportInboxFilter.open
                  ? 'No open reports'
                  : 'No completed reports',
              body: _inboxFilter == _ReportInboxFilter.open
                  ? 'The triage queue is clear. Resolved and dismissed reports are under Completed.'
                  : 'Resolved and dismissed reports will appear here after admin action.',
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = JiraniResponsive.isAdminWide(constraints.maxWidth);
              final paneHeight = (MediaQuery.sizeOf(context).height - 220)
                  .clamp(480.0, 740.0);
              final inboxContent = Column(
                children: [
                  for (final report in filteredReports)
                    AdminReportInboxTile(
                      report: adminReportRowFromReport(report),
                      selected: report.id == selectedReport?.id,
                      onTap: () =>
                          setState(() => _selectedReportId = report.id),
                    ),
                ],
              );
              final inbox = AdminPanel(
                title: 'Report Inbox',
                padding: EdgeInsets.zero,
                fillChild: wide,
                child: wide
                    ? ListView(
                        controller: _inboxScrollController,
                        padding: EdgeInsets.zero,
                        children: inboxContent.children,
                      )
                    : inboxContent,
              );
              final activeReport = selectedReport!;
              final activeRow = selected!;
              final evidenceUrls = _evidenceImageUrls(
                activeReport,
                selectedRequest,
              );
              final detailContent = _AdminReportCaseFile(
                report: activeReport,
                row: activeRow,
                request: selectedRequest,
                evidenceUrls: evidenceUrls,
                errorMessage: adminProvider.errorMessage,
                isLoading: adminProvider.isLoading,
                canResolve: _canResolveDispute(activeReport, selectedRequest),
                formatDate: _formatFullDate,
                onResolveBorrower: selectedRequest == null
                    ? null
                    : () => _resolveDispute(
                          context,
                          report: activeReport,
                          request: selectedRequest,
                          resolveForBorrower: true,
                        ),
                onResolveLender: selectedRequest == null
                    ? null
                    : () => _resolveDispute(
                          context,
                          report: activeReport,
                          request: selectedRequest,
                          resolveForBorrower: false,
                        ),
                onDismissReport: () => _dismissReport(
                  context,
                  report: activeReport,
                ),
                onIssueWarning: () => _issueWarning(
                  context,
                  report: activeReport,
                  row: activeRow,
                ),
              );
              final detail = AdminPanel(
                title: activeRow.title,
                action: activeRow.priority,
                fillChild: wide,
                child: wide
                    ? Scrollbar(
                        controller: _detailScrollController,
                        child: SingleChildScrollView(
                          controller: _detailScrollController,
                          child: detailContent,
                        ),
                      )
                    : detailContent,
              );

              if (wide) {
                return SizedBox(
                  height: paneHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 360, child: inbox),
                      const SizedBox(width: 20),
                      Expanded(child: detail),
                    ],
                  ),
                );
              }
              return Column(
                children: [inbox, const SizedBox(height: 20), detail],
              );
            },
          ),
      ],
    );
  }

  ReportModel? _selectedReport(List<ReportModel> reports) {
    if (reports.isEmpty) return null;
    final selectedId = _selectedReportId;
    if (selectedId != null) {
      for (final report in reports) {
        if (report.id == selectedId) return report;
      }
    }
    return reports.first;
  }

  BorrowRequest? _relatedBorrowRequest(
    List<BorrowRequest> requests,
    ReportModel report,
  ) {
    final id = report.relatedBorrowRequestId.trim();
    if (id.isEmpty) return null;
    for (final request in requests) {
      if (request.id == id) return request;
    }
    return null;
  }

  bool _canResolveDispute(ReportModel report, BorrowRequest? request) {
    return report.type == AppConstants.reportTypeDepositDispute &&
        report.status != AppConstants.reportStatusResolved &&
        request?.status == AppConstants.borrowStatusDisputed;
  }

  List<String> _evidenceImageUrls(ReportModel report, BorrowRequest? request) {
    final seen = <String>{};
    final urls = <String>[];
    for (final url in [
      report.evidenceImageUrl,
      request?.disputeEvidenceImageUrl ?? '',
      request?.minorIssuePhotoUrl ?? '',
      request?.returnProofImageUrl ?? '',
    ]) {
      final trimmed = url.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) continue;
      urls.add(trimmed);
    }
    return urls;
  }

  String _formatFullDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }

  Future<void> _resolveDispute(
    BuildContext context, {
    required ReportModel report,
    required BorrowRequest request,
    required bool resolveForBorrower,
  }) async {
    final reason = await _showResolutionReasonDialog(
      context,
      resolveForBorrower: resolveForBorrower,
    );
    if (reason == null || !context.mounted) return;
    final provider = context.read<AdminProvider>();
    final adminUid = provider.currentAdminUid;
    if (adminUid == null || adminUid.isEmpty) return;
    await provider.resolveMarketplaceDispute(
      report: report,
      borrowRequest: request,
      adminUid: adminUid,
      resolveForBorrower: resolveForBorrower,
      reason: reason,
    );
    if (!context.mounted) return;
    if (provider.errorMessage == null) {
      setState(() => _selectedReportId = null);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ??
              (resolveForBorrower
                  ? 'Dispute resolved for borrower.'
                  : 'Dispute resolved for lender.'),
        ),
      ),
    );
  }

  Future<String?> _showResolutionReasonDialog(
    BuildContext context, {
    required bool resolveForBorrower,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            resolveForBorrower
                ? 'Resolve for Borrower'
                : 'Resolve for Lender',
          ),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Resolution reason',
              hintText: 'Explain the admin decision',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.of(context).pop(value);
              },
              child: const Text('Resolve'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _dismissReport(
    BuildContext context, {
    required ReportModel report,
  }) async {
    final reason = await _showTextDecisionDialog(
      context,
      title: 'Dismiss Report',
      label: 'Dismissal reason',
      hint: 'Explain why this report does not need further action',
      actionLabel: 'Dismiss',
    );
    if (reason == null || !context.mounted) return;
    final provider = context.read<AdminProvider>();
    final adminUid = provider.currentAdminUid;
    if (adminUid == null || adminUid.isEmpty) return;
    await provider.dismissReport(
      report: report,
      adminUid: adminUid,
      reason: reason,
    );
    if (!context.mounted) return;
    if (provider.errorMessage == null) {
      setState(() => _selectedReportId = null);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.errorMessage ?? 'Report dismissed.')),
    );
  }

  Future<void> _issueWarning(
    BuildContext context, {
    required ReportModel report,
    required AdminReportRow row,
  }) async {
    final defaultMessage =
        'Your Community Trust Score or recent marketplace reviews have raised concern. Please communicate clearly, return borrowed items carefully, and resolve issues respectfully. Continued low ratings may cause residents to avoid transactions with you and may trigger further admin review.';
    final message = await _showTextDecisionDialog(
      context,
      title: 'Issue Warning',
      label: 'Warning message to resident',
      hint: 'Explain what the resident must improve',
      actionLabel: 'Send Warning',
      initialValue: row.title == 'Low Community Trust Score'
          ? defaultMessage
          : '${row.description}\n\n$defaultMessage',
    );
    if (message == null || !context.mounted) return;
    final provider = context.read<AdminProvider>();
    final adminUid = provider.currentAdminUid;
    if (adminUid == null || adminUid.isEmpty) return;
    await provider.issueUserWarningForReport(
      report: report,
      adminUid: adminUid,
      message: message,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ?? 'Warning sent to ${row.target}.',
        ),
      ),
    );
  }

  Future<String?> _showTextDecisionDialog(
    BuildContext context, {
    required String title,
    required String label,
    required String hint,
    required String actionLabel,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(labelText: label, hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.of(context).pop(value);
              },
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }
}

class AdminReportInboxTile extends StatelessWidget {
  const AdminReportInboxTile({
    super.key,
    required this.report,
    required this.selected,
    required this.onTap,
  });

  final AdminReportRow report;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      onTap: onTap,
      minVerticalPadding: 14,
      leading: AdminPriorityDot(priority: report.priority),
      title: Text(
        report.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${report.reporter} - ${report.description}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _AdminReportCaseFile extends StatelessWidget {
  const _AdminReportCaseFile({
    required this.report,
    required this.row,
    required this.request,
    required this.evidenceUrls,
    required this.errorMessage,
    required this.isLoading,
    required this.canResolve,
    required this.formatDate,
    required this.onResolveBorrower,
    required this.onResolveLender,
    required this.onDismissReport,
    required this.onIssueWarning,
  });

  final ReportModel report;
  final AdminReportRow row;
  final BorrowRequest? request;
  final List<String> evidenceUrls;
  final String? errorMessage;
  final bool isLoading;
  final bool canResolve;
  final String Function(DateTime value) formatDate;
  final VoidCallback? onResolveBorrower;
  final VoidCallback? onResolveLender;
  final VoidCallback onDismissReport;
  final VoidCallback onIssueWarning;

  @override
  Widget build(BuildContext context) {
    final disputeReason = _bestText(
      [request?.disputeReason, request?.minorIssueReason, row.description],
      fallback: 'No dispute reason was provided.',
    );
    final deposit = request?.depositAmount ?? 0;
    final deduction = request?.minorDeductionAmount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CaseSummaryBanner(
          title: row.title,
          priority: row.priority,
          status: request?.status ?? report.status,
          depositLabel: 'RM ${deposit.toStringAsFixed(2)}',
          itemTitle: request?.itemTitle ?? row.content,
        ),
        const SizedBox(height: 16),
        _PartyComparison(
          borrowerName: request?.borrowerName ?? row.target,
          borrowerEmail: request?.borrowerEmail ?? '',
          borrowerId: request?.borrowerId ?? report.reportedUserId,
          borrowerPhone: request?.borrowerPhoneNumber ?? '',
          borrowerReputationScore: request?.borrowerReputationScore,
          borrowerVerified: request?.borrowerVerified,
          lenderName: request?.ownerName ?? row.reporter,
          lenderEmail: request?.ownerEmail ?? '',
          lenderId: request?.ownerId ?? report.reporterId,
        ),
        const SizedBox(height: 16),
        _DisputeProblemCard(
          reason: disputeReason,
          reportedBy: row.reporter,
          reportedAgainst: row.target,
          returnedCondition: request?.itemConditionAfter ?? '',
          ownerNotes: request?.ownerReturnNotes ?? '',
          depositLabel: 'RM ${deposit.toStringAsFixed(2)}',
          deductionLabel: deduction > 0
              ? 'RM ${deduction.toStringAsFixed(2)} requested'
              : 'No partial deduction requested',
          evidenceUrls: evidenceUrls,
        ),
        const SizedBox(height: 16),
        _TransactionFactsCard(
          report: report,
          request: request,
          formatDate: formatDate,
        ),
        const SizedBox(height: 20),
        if (canResolve)
          _ResolutionActions(
            isLoading: isLoading,
            onResolveBorrower: onResolveBorrower,
            onResolveLender: onResolveLender,
          )
        else
          _GeneralReportActions(
            isLoading: isLoading,
            onDismissReport: onDismissReport,
            onIssueWarning: onIssueWarning,
          ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          AdminInlineAlert(message: errorMessage!),
        ],
      ],
    );
  }

  static String _bestText(List<String?> values, {required String fallback}) {
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }
}

class _CaseSummaryBanner extends StatelessWidget {
  const _CaseSummaryBanner({
    required this.title,
    required this.priority,
    required this.status,
    required this.depositLabel,
    required this.itemTitle,
  });

  final String title;
  final String priority;
  final String status;
  final String depositLabel;
  final String itemTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.primary.withValues(alpha: 0.18)),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  itemTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AdminColors.muted),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminStatusPill(label: priority, color: AdminColors.danger),
              AdminStatusPill(label: status, color: AdminColors.primary),
              _MiniMetric(label: 'Deposit held', value: depositLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartyComparison extends StatelessWidget {
  const _PartyComparison({
    required this.borrowerName,
    required this.borrowerEmail,
    required this.borrowerId,
    required this.borrowerPhone,
    required this.borrowerReputationScore,
    required this.borrowerVerified,
    required this.lenderName,
    required this.lenderEmail,
    required this.lenderId,
  });

  final String borrowerName;
  final String borrowerEmail;
  final String borrowerId;
  final String borrowerPhone;
  final double? borrowerReputationScore;
  final bool? borrowerVerified;
  final String lenderName;
  final String lenderEmail;
  final String lenderId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 720;
        final cards = [
          _PartyCard(
            role: 'Borrower',
            name: borrowerName,
            email: borrowerEmail,
            id: borrowerId,
            phone: borrowerPhone,
            score: borrowerReputationScore,
            verified: borrowerVerified,
            icon: Icons.person_rounded,
            accent: AdminColors.primary,
          ),
          _PartyCard(
            role: 'Lender',
            name: lenderName,
            email: lenderEmail,
            id: lenderId,
            phone: '',
            score: null,
            verified: null,
            icon: Icons.inventory_2_rounded,
            accent: AdminColors.danger,
          ),
        ];
        if (stacked) {
          return Column(
            children: [
              cards.first,
              const SizedBox(height: 12),
              cards.last,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards.first),
            const SizedBox(width: 12),
            Expanded(child: cards.last),
          ],
        );
      },
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({
    required this.role,
    required this.name,
    required this.email,
    required this.id,
    required this.phone,
    required this.score,
    required this.verified,
    required this.icon,
    required this.accent,
  });

  final String role;
  final String name;
  final String email;
  final String id;
  final String phone;
  final double? score;
  final bool? verified;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'Unknown resident' : name.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _softCardDecoration(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CompactFact(label: 'User ID', value: id),
          if (email.trim().isNotEmpty) _CompactFact(label: 'Email', value: email),
          if (phone.trim().isNotEmpty) _CompactFact(label: 'Phone', value: phone),
          if (score != null)
            _CompactFact(
              label: 'Trust score',
              value: '${score!.toStringAsFixed(1)} / 5',
            ),
          if (verified != null)
            _CompactFact(
              label: 'Verification',
              value: verified! ? 'Verified resident' : 'Not verified',
            ),
        ],
      ),
    );
  }
}

class _DisputeProblemCard extends StatelessWidget {
  const _DisputeProblemCard({
    required this.reason,
    required this.reportedBy,
    required this.reportedAgainst,
    required this.returnedCondition,
    required this.ownerNotes,
    required this.depositLabel,
    required this.deductionLabel,
    required this.evidenceUrls,
  });

  final String reason;
  final String reportedBy;
  final String reportedAgainst;
  final String returnedCondition;
  final String ownerNotes;
  final String depositLabel;
  final String deductionLabel;
  final List<String> evidenceUrls;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final heading = Row(
                children: const [
                  Icon(Icons.balance_rounded, color: AdminColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Problem Between Them',
                      style: TextStyle(
                        color: AdminColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
              final proofButton = AdminReportEvidencePreview(
                imageUrls: evidenceUrls,
              );
              if (constraints.maxWidth < 460) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    if (evidenceUrls.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      proofButton,
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: heading),
                  proofButton,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            reason,
            style: const TextStyle(
              color: AdminColors.ink,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniMetric(label: 'Reported by', value: reportedBy),
              _MiniMetric(label: 'Against', value: reportedAgainst),
              _MiniMetric(label: 'Deposit', value: depositLabel),
              _MiniMetric(label: 'Deduction', value: deductionLabel),
              if (returnedCondition.trim().isNotEmpty)
                _MiniMetric(label: 'Returned condition', value: returnedCondition),
            ],
          ),
          if (ownerNotes.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _NotesBlock(title: 'Lender notes', body: ownerNotes),
          ],
        ],
      ),
    );
  }
}

class _TransactionFactsCard extends StatelessWidget {
  const _TransactionFactsCard({
    required this.report,
    required this.request,
    required this.formatDate,
  });

  final ReportModel report;
  final BorrowRequest? request;
  final String Function(DateTime value) formatDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _softCardDecoration(AdminColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Case Details',
            style: TextStyle(
              color: AdminColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (request != null) ...[
            _CompactFact(label: 'Transaction ID', value: request!.id),
            _CompactFact(label: 'Item ID', value: request!.itemId),
            _CompactFact(label: 'Item', value: request!.itemTitle),
            _CompactFact(label: 'Request status', value: request!.status),
            _CompactFact(
              label: 'Deposit decision',
              value: request!.depositDecision,
            ),
            if (request!.adminResolution.trim().isNotEmpty)
              _CompactFact(
                label: 'Admin resolution',
                value: request!.adminResolution,
              ),
          ],
          _CompactFact(label: 'Report ID', value: report.id),
          _CompactFact(label: 'Report type', value: report.type),
          _CompactFact(label: 'Report status', value: report.status),
          _CompactFact(label: 'Created', value: formatDate(report.createdAt)),
          _CompactFact(label: 'Updated', value: formatDate(report.updatedAt)),
        ],
      ),
    );
  }
}

class _ResolutionActions extends StatelessWidget {
  const _ResolutionActions({
    required this.isLoading,
    required this.onResolveBorrower,
    required this.onResolveLender,
  });

  final bool isLoading;
  final VoidCallback? onResolveBorrower;
  final VoidCallback? onResolveLender;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: isLoading ? null : onResolveBorrower,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Resolve for Borrower'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: isLoading ? null : onResolveLender,
            icon: const Icon(Icons.gavel_rounded),
            label: const Text('Resolve for Lender'),
          ),
        ],
      ),
    );
  }
}

class _GeneralReportActions extends StatelessWidget {
  const _GeneralReportActions({
    required this.isLoading,
    required this.onDismissReport,
    required this.onIssueWarning,
  });

  final bool isLoading;
  final VoidCallback onDismissReport;
  final VoidCallback onIssueWarning;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: isLoading ? null : onDismissReport,
          icon: const Icon(Icons.close_rounded),
          label: const Text('Dismiss Report'),
        ),
        FilledButton.tonalIcon(
          onPressed: isLoading ? null : onIssueWarning,
          icon: const Icon(Icons.campaign_rounded),
          label: const Text('Issue Warning'),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AdminColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AdminColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactFact extends StatelessWidget {
  const _CompactFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 126,
            child: Text(
              label,
              style: const TextStyle(
                color: AdminColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              displayValue,
              style: const TextStyle(
                color: AdminColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesBlock extends StatelessWidget {
  const _NotesBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AdminColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: AdminColors.ink)),
        ],
      ),
    );
  }
}

BoxDecoration _softCardDecoration(Color accent) {
  return BoxDecoration(
    color: AdminColors.background,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: accent.withValues(alpha: 0.16)),
  );
}

class AdminReportDetailSection extends StatelessWidget {
  const AdminReportDetailSection({
    super.key,
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AdminColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line, style: const TextStyle(color: AdminColors.ink)),
            ),
        ],
      ),
    );
  }
}

class AdminReportEvidencePreview extends StatelessWidget {
  const AdminReportEvidencePreview({super.key, required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final candidates = imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
    if (candidates.isEmpty) return const SizedBox.shrink();

    return FilledButton.tonalIcon(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => _ProofEvidenceDialog(imageUrls: candidates),
      ),
      icon: const Icon(Icons.photo_library_rounded),
      label: Text(candidates.length == 1 ? 'View Proof' : 'View Proofs'),
    );
  }

  static Future<String?> _resolveEvidenceUrl(String rawUrl) async {
    final value = rawUrl.trim();
    if (value.isEmpty) return null;
    try {
      if (value.startsWith('gs://')) {
        return FirebaseStorage.instance.refFromURL(value).getDownloadURL();
      }
      if (value.startsWith('http')) {
        if (value.contains('firebasestorage.googleapis.com')) {
          try {
            return await FirebaseStorage.instance
                .refFromURL(value)
                .getDownloadURL();
          } catch (_) {
            return value;
          }
        }
        return value;
      }
      return FirebaseStorage.instance.ref().child(value).getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}

class _ProofEvidenceDialog extends StatelessWidget {
  const _ProofEvidenceDialog({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Proof Evidence',
                      style: TextStyle(
                        color: AdminColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AdminColors.border),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: imageUrls.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final rawUrl = imageUrls[index];
                  return FutureBuilder<String?>(
                    future: AdminReportEvidencePreview._resolveEvidenceUrl(
                      rawUrl,
                    ),
                    builder: (context, snapshot) {
                      final loading =
                          snapshot.connectionState != ConnectionState.done;
                      final resolvedUrl = snapshot.data?.trim() ?? '';
                      return _ProofEvidenceTile(
                        rawUrl: rawUrl,
                        resolvedUrl: resolvedUrl,
                        loading: loading,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofEvidenceTile extends StatelessWidget {
  const _ProofEvidenceTile({
    required this.rawUrl,
    required this.resolvedUrl,
    required this.loading,
  });

  final String rawUrl;
  final String resolvedUrl;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minHeight: 280, maxHeight: 460),
              color: AdminColors.surface,
              alignment: Alignment.center,
              child: loading
                  ? const CircularProgressIndicator()
                  : resolvedUrl.isEmpty
                      ? _EvidenceErrorMessage(rawUrl: rawUrl)
                      : Image.network(
                          resolvedUrl,
                          fit: BoxFit.contain,
                          webHtmlElementStrategy:
                              WebHtmlElementStrategy.prefer,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 280,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _EvidenceErrorMessage(rawUrl: rawUrl);
                          },
                        ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: resolvedUrl.isEmpty
                    ? null
                    : () => launchUrl(
                          Uri.parse(resolvedUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Proof Link'),
              ),
              SizedBox(
                width: 520,
                child: SelectableText(
                  rawUrl,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvidenceErrorMessage extends StatelessWidget {
  const _EvidenceErrorMessage({this.rawUrl = ''});

  final String rawUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      color: AdminColors.surface,
      padding: const EdgeInsets.all(16),
      child: Text(
        rawUrl.trim().isEmpty
            ? 'Could not load proof photo.'
            : 'Could not load proof photo. Stored reference: $rawUrl',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AdminColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
