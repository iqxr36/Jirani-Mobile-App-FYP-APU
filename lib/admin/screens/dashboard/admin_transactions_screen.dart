import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/models/admin_display_rows.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/admin/providers/admin_provider.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/report_model.dart';
import 'package:jirani/shared/models/service_request_model.dart';
import 'package:jirani/shared/utils/display_labels.dart';
import 'package:provider/provider.dart';

/// Admin payments screen: monitors marketplace deposits, unresolved disputes, manual payouts, and the platform ledger.
// Admin transactions UI feature: shows marketplace payments, deposit resolutions, and manual lender payouts.
class AdminTransactionsScreen extends StatelessWidget {
  const AdminTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final transactionRows = adminTransactionRowsFromRequests(
      admin.borrowRequests,
      admin.serviceRequests,
    );
    final depositQueue = admin.borrowRequests
        .where(_needsDepositResolution)
        .toList();
    final payoutQueue = admin.borrowRequests
        .where(_isVisibleManualPayout)
        .toList();
    final stuckPayoutCount = admin.borrowRequests
        .where(_isStuckManualPayout)
        .length;
    final serviceDisputeQueue = admin.serviceRequests
        .where((request) =>
            request.status == AppConstants.serviceRequestStatusDisputed)
        .toList();

    return AdminPageScroll(
      children: [
        AdminControlBar(
          title: 'Transactions Monitoring',
          subtitle:
              'Audit borrow deposits, task service payments, disputes, and completion status.',
          controls: const [
            AdminFilterChipButton(label: 'Date Range'),
            AdminFilterChipButton(label: 'Type'),
            AdminFilterChipButton(label: 'Status'),
          ],
        ),
        const SizedBox(height: 20),
        _DepositResolutionPanel(requests: depositQueue),
        const SizedBox(height: 20),
        _ManualPayoutPanel(
          requests: payoutQueue,
          stuckCount: stuckPayoutCount,
        ),
        const SizedBox(height: 20),
        _ServiceDisputePanel(requests: serviceDisputeQueue),
        const SizedBox(height: 20),
        AdminPanel(
          title: 'Platform Ledger',
          action: '${transactionRows.length} records',
          padding: EdgeInsets.zero,
          child: transactionRows.isEmpty
              ? const AdminEmptyPanelMessage(
                  icon: Icons.receipt_long_rounded,
                  title: 'No transactions found',
                  body:
                      'Borrow and task service requests will appear here.',
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                      color: AdminColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                    columns: const [
                      DataColumn(label: Text('Transaction ID')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Provider')),
                      DataColumn(label: Text('Requester')),
                      DataColumn(label: Text('Deposit')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: transactionRows
                        .map(
                          (tx) => DataRow(
                            cells: [
                              DataCell(Text(tx.id)),
                              DataCell(Text(tx.date)),
                              DataCell(Text(tx.type)),
                              DataCell(Text(tx.provider)),
                              DataCell(Text(tx.requester)),
                              DataCell(Text(tx.deposit)),
                              DataCell(
                                AdminStatusPill(
                                  label: tx.status,
                                  color: tx.color,
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }

  /// Admin payments: filters provider-paid disputed requests that still need a deposit refund/deduction decision.
  static bool _needsDepositResolution(BorrowRequest request) {
    final resolved = {
      AppConstants.depositStatusRefunded,
      AppConstants.depositStatusPartiallyRefunded,
      AppConstants.depositStatusDeducted,
      AppConstants.depositStatusNotRequired,
    };
    return request.paymentProvider == AppConstants.paymentProviderXendit &&
        request.paymentStatus == AppConstants.paymentStatusCompleted &&
        !resolved.contains(request.depositStatus) &&
        (request.status == AppConstants.borrowStatusDisputed ||
            request.depositStatus == AppConstants.depositStatusDisputed ||
            request.depositStatus == AppConstants.depositStatusRefundFailed);
  }

  static bool _isVisibleManualPayout(BorrowRequest request) {
    return request.manualPayoutStatus ==
        AppConstants.manualPayoutStatusPendingManual;
  }

  static bool _isStuckManualPayout(BorrowRequest request) {
    const resolved = {
      AppConstants.depositStatusRefunded,
      AppConstants.depositStatusPartiallyRefunded,
      AppConstants.depositStatusDeducted,
      AppConstants.depositStatusNotRequired,
    };
    return request.manualPayoutStatus == AppConstants.manualPayoutStatusBlocked &&
        resolved.contains(request.depositStatus) &&
        request.lenderTotalEarning > 0;
  }
}

class _ServiceDisputePanel extends StatelessWidget {
  const _ServiceDisputePanel({required this.requests});

  final List<ServiceRequestModel> requests;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: 'Service Disputes',
      action: '${requests.length} frozen',
      child: requests.isEmpty
          ? const AdminEmptyPanelMessage(
              icon: Icons.home_repair_service_outlined,
              title: 'No service disputes',
              body: 'Disputed paid service requests will appear here.',
            )
          : Column(
              children: [
                for (var i = 0; i < requests.length; i++) ...[
                  _ServiceDisputeCard(request: requests[i]),
                  if (i != requests.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _ServiceDisputeCard extends StatelessWidget {
  const _ServiceDisputeCard({required this.request});

  final ServiceRequestModel request;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final amount = request.amount ?? 0;
    final canResolve = admin.canResolveServiceDispute(request);
    final linkedReport = admin.serviceDisputeReportFor(request);
    final reportStatus = linkedReport == null
        ? admin.effectiveReportStatusForRequest(request)
        : admin.effectiveReportStatus(linkedReport);
    final canStartReview = admin.canStartServiceDisputeReviewFor(request);
    final isReopenReview = admin.isServiceDisputeReportReopen(request);
    return _AdminPaymentCard(
      icon: Icons.handyman_outlined,
      title: request.serviceTitle,
      subtitle:
          '${request.requesterName} -> ${request.providerName} | Held ${_adminMoney(amount)}',
      statusLabel: request.payoutStatus.isEmpty
          ? serviceRequestStatusLabel(request.status)
          : servicePayoutStatusLabel(request.payoutStatus),
      statusColor: AdminColors.warning,
      children: [
        _PaymentMetaRow(
          label: 'Payment',
          value: paymentStatusLabel(request.paymentStatus),
        ),
        _PaymentMetaRow(
          label: 'Refund',
          value: refundStatusLabel(request.refundStatus),
        ),
        _PaymentMetaRow(
          label: 'Dispute type',
          value: request.disputeType.trim().isEmpty
              ? 'Not specified'
              : serviceDisputeTypeLabel(request.disputeType),
        ),
        if (request.disputeReason.trim().isNotEmpty)
          _PaymentMetaRow(label: 'Details', value: request.disputeReason),
        if (request.disputeReportId.trim().isNotEmpty) ...[
          _PaymentMetaRow(
            label: 'Report status',
            value: reportStatus.isEmpty
                ? 'Not loaded'
                : reportStatusLabel(reportStatus),
          ),
          if (!canResolve) ...[
            const SizedBox(height: 8),
            Text(
              linkedReport == null
                  ? 'Linked report not found in this admin view. Open Reports to review the case first.'
                  : reportStatus == AppConstants.reportStatusDismissed
                  ? 'This report was dismissed but payment is still held. Reopen review to enable payout or refund.'
                  : reportStatus == AppConstants.reportStatusUnderReview
                  ? 'Report is under review. Payout and refund should be available now.'
                  : 'Start review on this dispute before forcing payout or refund.',
              style: const TextStyle(
                color: AdminColors.muted,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (canStartReview && linkedReport != null)
              _AdminActionButton(
                label: isReopenReview ? 'Reopen Review' : 'Start Review',
                icon: Icons.fact_check_rounded,
                onTap: admin.isLoading
                    ? null
                    : () => _startServiceDisputeReview(
                          context,
                          report: linkedReport,
                          reopening: isReopenReview,
                        ),
              ),
            _AdminActionButton(
              label: 'Force Payout',
              icon: Icons.payments_outlined,
              onTap: admin.isLoading || !canResolve
                  ? null
                  : () => _showServiceResolutionDialog(
                        context,
                        request,
                        refund: false,
                      ),
            ),
            _AdminActionButton(
              label: 'Refund',
              icon: Icons.reply_rounded,
              danger: true,
              onTap: admin.isLoading || !canResolve
                  ? null
                  : () => _showServiceResolutionDialog(
                        context,
                        request,
                        refund: true,
                      ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _startServiceDisputeReview(
    BuildContext context, {
    required ReportModel report,
    bool reopening = false,
  }) async {
    final admin = context.read<AdminProvider>();
    final adminUid = admin.currentAdminUid;
    if (adminUid == null || adminUid.isEmpty) return;
    await admin.markServiceDisputeUnderReview(
      report: report,
      adminUid: adminUid,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          admin.errorMessage ??
              (reopening
                  ? 'Dispute review reopened. You can now force payout or refund.'
                  : 'Dispute marked under review. You can now force payout or refund.'),
        ),
      ),
    );
  }

  Future<void> _showServiceResolutionDialog(
    BuildContext context,
    ServiceRequestModel request, {
    required bool refund,
  }) async {
    final reasonController = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(refund ? 'Refund Requester' : 'Force Provider Payout'),
            content: TextField(
              controller: reasonController,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Admin reason',
                hintText: 'Explain the resolution for both residents',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) return;
                  final admin = context.read<AdminProvider>();
                  if (refund) {
                    await admin.refundServicePayment(
                      serviceRequest: request,
                      reason: reason,
                    );
                  } else {
                    await admin.forceServicePayout(
                      serviceRequest: request,
                      reason: reason,
                    );
                  }
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: Text(refund ? 'Refund' : 'Release Payout'),
              ),
            ],
          );
        },
      );
    } finally {
      reasonController.dispose();
    }
  }
}

/// Admin payments UI: lists payment-provider deposit disputes that admin must resolve.
// Admin deposit UI feature: groups disputed deposits that need admin refund/deduction decisions.
class _DepositResolutionPanel extends StatelessWidget {
  const _DepositResolutionPanel({required this.requests});

  final List<BorrowRequest> requests;

  @override
  /// Admin payments UI: builds the deposit resolution queue, manual payout queue, and read-only ledger table.
  /// Admin payments UI: renders deposit dispute cards or an empty state.
  Widget build(BuildContext context) {
    return AdminPanel(
      title: 'Deposit Resolution',
      action: '${requests.length} open',
      child: requests.isEmpty
          ? const AdminEmptyPanelMessage(
              icon: Icons.verified_user_outlined,
              title: 'No deposit disputes',
              body: 'Paid marketplace disputes will appear here.',
            )
          : Column(
              children: [
                for (var i = 0; i < requests.length; i++) ...[
                  _DepositResolutionCard(request: requests[i]),
                  if (i != requests.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

/// Admin payments UI: one disputed deposit card with full refund, partial deduction, and full deduction actions.
// Admin deposit UI feature: shows one disputed deposit and opens the resolution dialog.
class _DepositResolutionCard extends StatelessWidget {
  const _DepositResolutionCard({required this.request});

  final BorrowRequest request;

  @override
  /// Admin payments UI: renders deposit facts and resolution buttons for one borrow request.
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final deposit = request.depositAmount ?? 0;

    return _AdminPaymentCard(
      icon: Icons.gpp_maybe_outlined,
      title: request.itemTitle,
      subtitle:
          '${request.borrowerName} -> ${request.ownerName} | Deposit ${_adminMoney(deposit)}',
      statusLabel: request.depositStatus.isEmpty
          ? borrowRequestStatusLabel(request.status)
          : depositStatusLabel(request.depositStatus),
      statusColor: request.depositStatus == AppConstants.depositStatusRefundFailed
          ? AdminColors.danger
          : AdminColors.warning,
      children: [
        _PaymentMetaRow(
          label: 'Refund status',
          value: refundStatusLabel(request.refundStatus),
        ),
        _PaymentMetaRow(
          label: 'Requested deduction',
          value: _adminMoney(request.minorDeductionAmount ?? 0),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _AdminActionButton(
              label: 'Full Refund',
              icon: Icons.reply_rounded,
              onTap: admin.isLoading
                  ? null
                  : () => _showDepositDialog(
                        context,
                        request,
                        AppConstants.depositResolutionFullRefund,
                      ),
            ),
            _AdminActionButton(
              label: 'Partial Deduction',
              icon: Icons.price_change_outlined,
              onTap: admin.isLoading
                  ? null
                  : () => _showDepositDialog(
                        context,
                        request,
                        AppConstants.depositResolutionPartialDeduction,
                      ),
            ),
            _AdminActionButton(
              label: 'Full Deduction',
              icon: Icons.lock_outline_rounded,
              danger: true,
              onTap: admin.isLoading
                  ? null
                  : () => _showDepositDialog(
                        context,
                        request,
                        AppConstants.depositResolutionFullDeduction,
                      ),
            ),
          ],
        ),
      ],
    );
  }

  /// Admin payments: collects admin reason/deduction, then calls the backend deposit resolver.
  // Admin deposit UI feature: collects decision, deduction amount, and reason before calling backend resolution.
  Future<void> _showDepositDialog(
    BuildContext context,
    BorrowRequest request,
    String decision,
  ) async {
    final pageContext = context;
    final reasonController = TextEditingController();
    final deductionController = TextEditingController(
      text: decision == AppConstants.depositResolutionPartialDeduction
          ? ((request.minorDeductionAmount ?? 0) > 0
              ? (request.minorDeductionAmount ?? 0).toStringAsFixed(2)
              : '')
          : '',
    );
    try {
      final confirmed = await showDialog<bool>(
        context: pageContext,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(_resolutionTitle(decision)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (decision == AppConstants.depositResolutionPartialDeduction)
                  TextField(
                    controller: deductionController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Damage deduction (RM)',
                    ),
                  ),
                if (decision == AppConstants.depositResolutionPartialDeduction)
                  const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Admin reason',
                    hintText: 'Explain the decision for both residents',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (reasonController.text.trim().isEmpty) return;
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text('Resolve'),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !pageContext.mounted) return;

      final reason = reasonController.text.trim();
      final deduction = _deductionForDecision(
        decision,
        request.depositAmount ?? 0,
        deductionController.text,
      );
      final adminProvider = pageContext.read<AdminProvider>();
      await adminProvider.resolveMarketplaceDeposit(
        borrowRequest: request,
        decision: decision,
        damageDeductionAmount: deduction,
        reason: reason,
        reportId: request.disputeReportId,
      );
      if (!pageContext.mounted) return;

      final messenger = ScaffoldMessenger.of(pageContext);
      final error = adminProvider.errorMessage;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Deposit resolution saved for ${request.itemTitle}.',
          ),
          backgroundColor: error == null ? null : AdminColors.danger,
        ),
      );
    } finally {
      reasonController.dispose();
      deductionController.dispose();
    }
  }
}

/// Admin payouts UI: lists lender earnings that must be paid manually.
// Admin payout UI feature: groups lender manual payouts waiting for collection or already paid.
class _ManualPayoutPanel extends StatelessWidget {
  const _ManualPayoutPanel({
    required this.requests,
    required this.stuckCount,
  });

  final List<BorrowRequest> requests;
  final int stuckCount;

  @override
  /// Admin payouts UI: renders pending manual payout cards or an empty state.
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final readyCount = requests.length;
    final actionLabel = stuckCount > 0
        ? '$readyCount ready, $stuckCount stuck'
        : '$readyCount ready';
    return AdminPanel(
      title: 'Manual Lender Payouts',
      action: actionLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stuckCount > 0) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: _AdminActionButton(
                label: 'Repair $stuckCount stuck payout${stuckCount == 1 ? '' : 's'}',
                icon: Icons.build_circle_outlined,
                onTap: admin.isLoading
                    ? null
                    : () => admin.repairStuckMarketplaceSettlement(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (requests.isEmpty)
            const AdminEmptyPanelMessage(
              icon: Icons.payments_outlined,
              title: 'No payouts ready',
              body:
                  'Completed marketplace transactions will appear here after deposits are settled.',
            )
          else
            Column(
              children: [
                for (var i = 0; i < requests.length; i++) ...[
                  _ManualPayoutCard(
                    request: requests[i],
                    isLoading: admin.isLoading,
                  ),
                  if (i != requests.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// Admin payouts UI: one lender payout card showing item fee, damage deduction, and mark-paid action.
// Admin payout UI feature: shows one lender payout and opens the mark-paid dialog.
class _ManualPayoutCard extends StatelessWidget {
  const _ManualPayoutCard({
    required this.request,
    required this.isLoading,
  });

  final BorrowRequest request;
  final bool isLoading;

  @override
  /// Admin payouts UI: renders payout amount details and action button for one lender.
  Widget build(BuildContext context) {
    final isReady =
        request.manualPayoutStatus == AppConstants.manualPayoutStatusPendingManual;
    final isSimulated =
        request.settlementMode == AppConstants.settlementModeSimulated;
    return _AdminPaymentCard(
      icon: Icons.account_balance_wallet_outlined,
      title: request.ownerName,
      subtitle:
          '${request.itemTitle} | Earning ${_adminMoney(request.lenderTotalEarning)}',
      statusLabel: isSimulated
          ? 'Ready (Test)'
          : manualPayoutStatusLabel(request.manualPayoutStatus),
      statusColor: AdminColors.primary,
      children: [
        _PaymentMetaRow(
          label: 'Item fee',
          value: _adminMoney(request.lenderBaseEarning),
        ),
        _PaymentMetaRow(
          label: 'Damage deduction',
          value: _adminMoney(request.lenderDamageEarning),
        ),
        if (request.refundStatus.isNotEmpty &&
            request.refundStatus != AppConstants.refundStatusNotRequired) ...[
          _PaymentMetaRow(
            label: 'Borrower refund',
            value: refundStatusLabel(request.refundStatus),
          ),
        ],
        if (isSimulated)
          const Text(
            'Test settlement mode: borrower refund and lender payout are recorded without live Xendit settlement.',
            style: TextStyle(color: AdminColors.muted),
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: _AdminActionButton(
            label: 'Mark Paid',
            icon: Icons.done_all_rounded,
            onTap: isLoading || !isReady
                ? null
                : () => _showPayoutDialog(context, request),
          ),
        ),
      ],
    );
  }

  /// Admin payouts: collects optional reference/note and records that admin paid the lender manually.
  // Admin payout UI feature: records payout reference/note when admin hands money to the lender.
  Future<void> _showPayoutDialog(
    BuildContext context,
    BorrowRequest request,
  ) async {
    final pageContext = context;
    final referenceController = TextEditingController();
    final noteController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: pageContext,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Record Manual Payout'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Reference',
                        hintText: 'Bank transfer reference',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        hintText: 'Optional internal note',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Mark Paid'),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !pageContext.mounted) return;

      final adminProvider = pageContext.read<AdminProvider>();
      await adminProvider.markManualPayoutPaid(
        borrowRequest: request,
        reference: referenceController.text,
        note: noteController.text,
      );
      if (!pageContext.mounted) return;

      final messenger = ScaffoldMessenger.of(pageContext);
      final error = adminProvider.errorMessage;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Manual payout marked paid for ${request.ownerName}.',
          ),
          backgroundColor: error == null ? null : AdminColors.danger,
        ),
      );
    } finally {
      referenceController.dispose();
      noteController.dispose();
    }
  }
}

/// Admin payments UI component: shared card for deposit resolution and manual payout queue rows.
class _AdminPaymentCard extends StatelessWidget {
  const _AdminPaymentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AdminColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AdminColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AdminStatusPill(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _PaymentMetaRow extends StatelessWidget {
  const _PaymentMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AdminColors.muted),
            ),
          ),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              color: AdminColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  const _AdminActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AdminColors.danger : AdminColors.primary;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.45)),
      ),
    );
  }
}

double _deductionForDecision(
  String decision,
  double depositAmount,
  String partialInput,
) {
  if (decision == AppConstants.depositResolutionFullRefund) return 0;
  if (decision == AppConstants.depositResolutionFullDeduction) {
    return depositAmount;
  }
  return double.tryParse(partialInput.trim()) ?? 0;
}

String _resolutionTitle(String decision) {
  switch (decision) {
    case AppConstants.depositResolutionFullRefund:
      return 'Refund Full Deposit';
    case AppConstants.depositResolutionPartialDeduction:
      return 'Apply Partial Deduction';
    case AppConstants.depositResolutionFullDeduction:
      return 'Deduct Full Deposit';
    default:
      return 'Resolve Deposit';
  }
}

String _adminMoney(double? value) {
  final amount = value ?? 0;
  final text = amount % 1 == 0
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  return 'RM $text';
}
