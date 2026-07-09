part of '../admin_reports_screen.dart';

// Admin reports UI feature: inbox-style report triage for disputes, chat reports, trust issues, and warnings.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key, this.selectedReportId});

  final String? selectedReportId;

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String? _selectedReportId;
  _ReportInboxFilter _inboxFilter = _ReportInboxFilter.open;
  final ScrollController _detailScrollController = ScrollController();
  final ScrollController _inboxScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedReportId = widget.selectedReportId;
  }

  @override
  void didUpdateWidget(covariant AdminReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextId = widget.selectedReportId;
    if (nextId != null && nextId != oldWidget.selectedReportId) {
      setState(() {
        _selectedReportId = nextId;
        _inboxFilter = _ReportInboxFilter.open;
      });
    }
  }

  // Admin reports UI feature: switches the inbox between priority/open/completed report filters.
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
    final selectedServiceRequest = selectedReport == null
        ? null
        : _relatedServiceRequest(adminProvider.serviceRequests, selectedReport);
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
                selectedServiceRequest,
              );
              final evidenceItems = _evidenceItems(
                activeReport,
                selectedRequest,
                selectedServiceRequest,
              );
              final detailContent = _AdminReportCaseFile(
                report: activeReport,
                row: activeRow,
                request: selectedRequest,
                serviceRequest: selectedServiceRequest,
                evidenceUrls: evidenceUrls,
                evidenceItems: evidenceItems,
                errorMessage: adminProvider.errorMessage,
                isLoading: adminProvider.isLoading,
                canResolve: _canResolveDispute(activeReport, selectedRequest),
                canStartServiceDisputeReview: _canStartServiceDisputeReview(
                  activeReport,
                  adminProvider,
                  selectedServiceRequest,
                ),
                serviceDisputeReopenReview: _isServiceDisputeReopenReview(
                  activeReport,
                  adminProvider,
                  selectedServiceRequest,
                ),
                canDismissServiceDisputeReport:
                    adminProvider.canDismissServiceDisputeReport(
                  selectedServiceRequest,
                ),
                serviceDisputeUnderReview: _isServiceDisputeUnderReview(
                  activeReport,
                  adminProvider,
                ),
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
                onStartServiceDisputeReview: _canStartServiceDisputeReview(
                      activeReport,
                      adminProvider,
                      selectedServiceRequest,
                    )
                    ? () => _startServiceDisputeReview(
                          context,
                          report: activeReport,
                        )
                    : null,
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

  ServiceRequestModel? _relatedServiceRequest(
    List<ServiceRequestModel> requests,
    ReportModel report,
  ) {
    final id = report.relatedServiceRequestId.trim();
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

  bool _canStartServiceDisputeReview(
    ReportModel report,
    AdminProvider adminProvider,
    ServiceRequestModel? serviceRequest,
  ) {
    if (report.type != AppConstants.reportTypeServiceDispute) return false;
    if (serviceRequest != null) {
      return adminProvider.canStartServiceDisputeReviewFor(serviceRequest);
    }
    final status = adminProvider.effectiveReportStatus(report);
    return status.isEmpty ||
        status == AppConstants.reportStatusOpen ||
        status == AppConstants.reportStatusDismissed;
  }

  bool _isServiceDisputeReopenReview(
    ReportModel report,
    AdminProvider adminProvider,
    ServiceRequestModel? serviceRequest,
  ) {
    if (report.type != AppConstants.reportTypeServiceDispute) return false;
    if (serviceRequest != null) {
      return adminProvider.isServiceDisputeReportReopen(serviceRequest);
    }
    return adminProvider.effectiveReportStatus(report) ==
        AppConstants.reportStatusDismissed;
  }

  bool _isServiceDisputeUnderReview(
    ReportModel report,
    AdminProvider adminProvider,
  ) {
    return report.type == AppConstants.reportTypeServiceDispute &&
        adminProvider.effectiveReportStatus(report) ==
            AppConstants.reportStatusUnderReview;
  }

  List<String> _evidenceImageUrls(
    ReportModel report,
    BorrowRequest? request,
    ServiceRequestModel? serviceRequest,
  ) {
    final seen = <String>{};
    final urls = <String>[];
    for (final url in [
      report.evidenceImageUrl,
      request?.disputeEvidenceImageUrl ?? '',
      request?.minorIssuePhotoUrl ?? '',
      request?.returnProofImageUrl ?? '',
      ...report.requesterEvidenceUrls,
      ...report.providerEvidenceUrls,
      ...serviceRequest?.requesterDisputeEvidenceUrls ?? const <String>[],
      ...serviceRequest?.providerDisputeEvidenceUrls ?? const <String>[],
      ...report.reportedMessages
          .where(
            (message) =>
                message.type == AppConstants.chatMessageImage &&
                message.mediaUrl.trim().isNotEmpty,
          )
          .map((message) => message.mediaUrl),
    ]) {
      final trimmed = url.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) continue;
      urls.add(trimmed);
    }
    return urls;
  }

  List<AdminReportEvidenceItem> _evidenceItems(
    ReportModel report,
    BorrowRequest? request,
    ServiceRequestModel? serviceRequest,
  ) {
    final seen = <String>{};
    final items = <AdminReportEvidenceItem>[];
    void add(String label, String url) {
      final trimmed = url.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) return;
      items.add(AdminReportEvidenceItem(label: label, imageUrl: trimmed));
    }

    if (request != null) {
      add('Before handover', request.handoverProofImageUrl);
      add('After return proof', request.returnProofImageUrl);
      add('Dispute proof', request.disputeEvidenceImageUrl);
      add('Minor damage photo', request.minorIssuePhotoUrl);
    }
    if (serviceRequest != null) {
      for (final url in serviceRequest.requesterDisputeEvidenceUrls) {
        add('Requester proof', url);
      }
      for (final url in serviceRequest.providerDisputeEvidenceUrls) {
        add('Provider proof', url);
      }
    }
    for (final url in report.requesterEvidenceUrls) {
      add('Requester proof', url);
    }
    for (final url in report.providerEvidenceUrls) {
      add('Provider proof', url);
    }
    add('Report proof', report.evidenceImageUrl);
    for (final message in report.reportedMessages.where(
      (message) =>
          message.type == AppConstants.chatMessageImage &&
          message.mediaUrl.trim().isNotEmpty,
    )) {
      add('Reported chat image', message.mediaUrl);
    }
    return items;
  }

  String _formatFullDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }

  // Admin reports UI feature: sends borrower/lender dispute resolution decisions to AdminProvider.
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

  // Admin reports UI feature: asks admin for a required dispute resolution reason.
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

  Future<void> _startServiceDisputeReview(
    BuildContext context, {
    required ReportModel report,
  }) async {
    final provider = context.read<AdminProvider>();
    final adminUid = provider.currentAdminUid;
    if (adminUid == null || adminUid.isEmpty) return;
    await provider.markServiceDisputeUnderReview(
      report: report,
      adminUid: adminUid,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ??
              'Service dispute marked under review. Resolve payout or refund in Transactions.',
        ),
      ),
    );
  }

  // Admin reports UI feature: dismisses a report after collecting an admin reason.
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

  // Admin reports UI feature: sends an admin warning notification to the reported resident.
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

  // Admin reports UI feature: shared text dialog for dismissal/warning decisions.
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
