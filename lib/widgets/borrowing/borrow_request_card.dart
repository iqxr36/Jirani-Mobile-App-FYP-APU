import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/models/borrow_request.dart';
import 'package:fyp_flutter_application/widgets/borrowing/borrow_status_chip.dart';

class BorrowRequestCard extends StatelessWidget {
  const BorrowRequestCard({
    super.key,
    required this.request,
    required this.onViewDetails,
    this.onCancel,
    this.onReview,
    this.showBorrower = false,
  });

  final BorrowRequest request;
  final VoidCallback onViewDetails;
  final VoidCallback? onCancel;
  final VoidCallback? onReview;
  final bool showBorrower;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.itemTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(showBorrower ? 'Borrower: ${request.borrowerName}' : 'Owner: ${request.ownerName}'),
            Text('Dates: ${_fmtDate(request.requestedStartDate)} to ${_fmtDate(request.expectedReturnDate)}'),
            const SizedBox(height: 6),
            Text(_feeDepositLabel(request)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                BorrowStatusChip(status: request.status),
                OutlinedButton(onPressed: onViewDetails, child: const Text('View Details')),
                if (onReview != null) FilledButton.tonal(onPressed: onReview, child: const Text('Review')),
                if (onCancel != null && request.status == AppConstants.borrowStatusPending)
                  OutlinedButton(onPressed: onCancel, child: const Text('Cancel Request')),
              ],
            ),
            if (request.status == AppConstants.borrowStatusRejected && request.rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Reason: ${request.rejectionReason}', style: const TextStyle(color: Colors.red)),
            ],
            if (request.status == AppConstants.borrowStatusApproved) ...[
              const SizedBox(height: 6),
              const Text('Approved — confirm pickup readiness in request details.'),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static String _feeDepositLabel(BorrowRequest request) {
    final hasFee = request.hasUsageFee && (request.usageFeeAmount ?? 0) > 0;
    final hasDeposit = request.hasDeposit && (request.depositAmount ?? 0) > 0;
    if (!hasFee && !hasDeposit) return 'Free';
    if (hasFee && hasDeposit) {
      return 'Fee: RM ${_fmtAmount(request.usageFeeAmount!)} + Deposit: RM ${_fmtAmount(request.depositAmount!)}';
    }
    if (hasFee) return 'Fee: RM ${_fmtAmount(request.usageFeeAmount!)}';
    return 'Deposit: RM ${_fmtAmount(request.depositAmount!)}';
  }

  static String _fmtAmount(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}
