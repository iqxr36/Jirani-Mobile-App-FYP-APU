import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/models/admin_display_rows.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/admin/providers/admin_provider.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/borrow_request.dart';
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
        .where(
          (request) =>
              request.manualPayoutStatus ==
              AppConstants.manualPayoutStatusPendingManual,
        )
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
        _ManualPayoutPanel(requests: payoutQueue),
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
          ? request.status
          : request.depositStatus,
      statusColor: request.depositStatus == AppConstants.depositStatusRefundFailed
          ? AdminColors.danger
          : AdminColors.warning,
      children: [
        _PaymentMetaRow(label: 'Refund status', value: request.refundStatus),
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
    final reasonController = TextEditingController();
    final deductionController = TextEditingController(
      text: decision == AppConstants.depositResolutionPartialDeduction
          ? ((request.minorDeductionAmount ?? 0) > 0
              ? (request.minorDeductionAmount ?? 0).toStringAsFixed(2)
              : '')
          : '',
    );
    try {
      await showDialog<void>(
        context: context,
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
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) return;
                  final deduction = _deductionForDecision(
                    decision,
                    request.depositAmount ?? 0,
                    deductionController.text,
                  );
                  await context.read<AdminProvider>().resolveMarketplaceDeposit(
                        borrowRequest: request,
                        decision: decision,
                        damageDeductionAmount: deduction,
                        reason: reason,
                        reportId: request.disputeReportId,
                      );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('Resolve'),
              ),
            ],
          );
        },
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
  const _ManualPayoutPanel({required this.requests});

  final List<BorrowRequest> requests;

  @override
  /// Admin payouts UI: renders pending manual payout cards or an empty state.
  Widget build(BuildContext context) {
    return AdminPanel(
      title: 'Manual Lender Payouts',
      action: '${requests.length} ready',
      child: requests.isEmpty
          ? const AdminEmptyPanelMessage(
              icon: Icons.payments_outlined,
              title: 'No payouts ready',
              body:
                  'Completed marketplace transactions will appear here after deposits are settled.',
            )
          : Column(
              children: [
                for (var i = 0; i < requests.length; i++) ...[
                  _ManualPayoutCard(request: requests[i]),
                  if (i != requests.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

/// Admin payouts UI: one lender payout card showing item fee, damage deduction, and mark-paid action.
// Admin payout UI feature: shows one lender payout and opens the mark-paid dialog.
class _ManualPayoutCard extends StatelessWidget {
  const _ManualPayoutCard({required this.request});

  final BorrowRequest request;

  @override
  /// Admin payouts UI: renders payout amount details and action button for one lender.
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return _AdminPaymentCard(
      icon: Icons.account_balance_wallet_outlined,
      title: request.ownerName,
      subtitle:
          '${request.itemTitle} | Earning ${_adminMoney(request.lenderTotalEarning)}',
      statusLabel: request.manualPayoutStatus,
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
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: _AdminActionButton(
            label: 'Mark Paid',
            icon: Icons.done_all_rounded,
            onTap: admin.isLoading
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
    final referenceController = TextEditingController();
    final noteController = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Record Manual Payout'),
            content: Column(
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
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  await context.read<AdminProvider>().markManualPayoutPaid(
                        borrowRequest: request,
                        reference: referenceController.text,
                        note: noteController.text,
                      );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('Mark Paid'),
              ),
            ],
          );
        },
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
