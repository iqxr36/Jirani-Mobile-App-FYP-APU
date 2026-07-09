part of '../resident_item_listing_view.dart';

ItemListingPricingType _pricingTypeFromItem(ItemModel item) {
  if (item.hasUsageFee && item.hasDeposit) {
    return ItemListingPricingType.feeAndDeposit;
  }
  if (item.hasUsageFee) return ItemListingPricingType.feeOnly;
  if (item.hasDeposit) return ItemListingPricingType.depositOnly;
  return ItemListingPricingType.free;
}

String _amountText(double? amount) {
  if (amount == null) return '';
  return amount % 1 == 0
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
}

String _money(double? amount) {
  return 'RM ${_amountText(amount ?? 0)}';
}

String _categoryLabel(String category) => itemCategoryLabel(category);

String _conditionLabel(String condition) => itemConditionLabel(condition);

String _handoverConditionLabel(String condition) {
  final label = lookupDisplayLabel(condition);
  return condition.trim().isEmpty ? 'Not recorded' : label;
}

String _returnConditionLabel(String condition) {
  final label = lookupDisplayLabel(condition);
  return condition.trim().isEmpty ? 'Not recorded' : label;
}

String _depositDecisionLabel(String decision) {
  if (decision.trim().isEmpty) return 'Not recorded';
  return depositDecisionLabel(decision);
}

String _statusLabel(ItemModel item) {
  if (_itemIsAdminArchived(item)) {
    return 'Action required';
  }
  if (_itemIsArchived(item)) {
    return 'Archived';
  }
  if (item.status == AppConstants.itemStatusAvailable) return 'Available';
  if (item.status == AppConstants.itemStatusUnavailable) return 'Unavailable';
  if (item.status == AppConstants.itemStatusBorrowed) return 'Borrowed';
  return itemStatusLabel(item.status);
}

_StatusTone _itemStatusTone(ItemModel item) {
  if (_itemIsAdminArchived(item)) {
    return _StatusTone.warning;
  }
  if (_itemIsArchived(item)) {
    return _StatusTone.neutral;
  }
  if (item.status == AppConstants.itemStatusAvailable) {
    return _StatusTone.success;
  }
  return _StatusTone.warning;
}

bool _listingHasLiveBorrow(ItemModel item) {
  if (_itemIsArchived(item)) {
    return false;
  }
  return item.status != AppConstants.itemStatusAvailable;
}

bool _itemIsArchived(ItemModel item) {
  return item.isArchived || item.status == AppConstants.itemStatusArchived;
}

bool _itemIsAdminArchived(ItemModel item) {
  return _itemIsArchived(item) && item.adminModerationReason.trim().isNotEmpty;
}

int _pendingRequestCountForItem(String itemId, List<BorrowRequest> requests) {
  return requests
      .where(
        (request) => request.itemId == itemId && _requestIsPending(request),
      )
      .length;
}

bool _requestIsPending(BorrowRequest request) {
  return request.status == AppConstants.borrowStatusPending;
}

String _requestDateRange(BorrowRequest request) {
  final start = _shortDateFormat.format(request.requestedStartDate);
  final end = _shortDateFormat.format(request.expectedReturnDate);
  return start == end ? start : '$start - $end';
}

String _requestStatusLabel(BorrowRequest request) {
  return borrowRequestStatusLabel(
    request.status,
    paymentComplete: MarketplaceBorrowFlow.isPaymentComplete(request),
    lenderApprovedLabel: true,
  );
}

_StatusTone _requestStatusTone(BorrowRequest request) {
  switch (request.status) {
    case AppConstants.borrowStatusPending:
      return _StatusTone.warning;
    case AppConstants.borrowStatusRejected:
    case AppConstants.borrowStatusCancelled:
    case AppConstants.borrowStatusDisputed:
      return _StatusTone.danger;
    case AppConstants.borrowStatusMinorIssuePending:
      return _StatusTone.warning;
    case AppConstants.borrowStatusCompleted:
      return _StatusTone.success;
    default:
      return _StatusTone.neutral;
  }
}

String _requestReadOnlyMessage(BorrowRequest request) {
  switch (request.status) {
    case AppConstants.borrowStatusApproved:
      return MarketplaceBorrowFlow.isPaymentComplete(request)
          ? 'The borrower has paid. Start handover when you meet them in person.'
          : 'Request approved. The borrower must complete payment before pickup coordination continues.';
    case AppConstants.borrowStatusRejected:
      return request.rejectionReason.isEmpty
          ? 'This request has been rejected.'
          : request.rejectionReason;
    case AppConstants.borrowStatusCancelled:
      return 'The borrower cancelled this request.';
    case AppConstants.borrowStatusCompleted:
      return 'This borrowing transaction is complete.';
    case AppConstants.borrowStatusMinorIssuePending:
      return 'The borrower is reviewing your requested deduction.';
    case AppConstants.borrowStatusDisputed:
      return 'This transaction is frozen for admin dispute review.';
    default:
      return 'This request is no longer pending, so approval actions are locked.';
  }
}

String _depositSummaryMessage(BorrowRequest request) {
  if (!request.hasDeposit) {
    return 'The return is confirmed. No deposit was required for this item.';
  }
  if (request.depositDecision == AppConstants.depositDecisionReturnDeposit) {
    return 'The return is confirmed and the deposit was released automatically.';
  }
  if (request.depositDecision == AppConstants.depositDecisionWithholdDeposit) {
    final reason = request.depositDecisionReason.trim();
    return reason.isEmpty
        ? 'The return is confirmed and the deposit was withheld.'
        : 'The return is confirmed and the deposit was withheld. Reason: $reason';
  }
  if (request.depositDecision == AppConstants.depositDecisionPartialDeduction) {
    final amount = request.minorDeductionAmount ?? 0;
    return 'The return is complete. ${_money(amount)} was deducted from the deposit for the accepted minor issue.';
  }
  return 'The return is confirmed. Deposit decision is pending.';
}

bool _hasLenderAdminDecision(BorrowRequest request) {
  return request.adminResolvedAt != null ||
      request.adminResolutionReason.trim().isNotEmpty ||
      request.manualPayoutStatus != AppConstants.manualPayoutStatusNotReady ||
      request.damageDecision.startsWith('admin_');
}

String _lenderAdminDecisionTitle(BorrowRequest request) {
  if (request.manualPayoutStatus == AppConstants.manualPayoutStatusPaid) {
    return 'Manual Payout Paid';
  }
  if (request.manualPayoutStatus ==
      AppConstants.manualPayoutStatusPendingManual) {
    return 'Manual Payout Ready';
  }
  if (request.manualPayoutStatus == AppConstants.manualPayoutStatusBlocked) {
    return 'Payout Blocked';
  }
  if (request.depositStatus == AppConstants.depositStatusRefunded) {
    return 'Deposit Returned to Borrower';
  }
  if (request.depositStatus == AppConstants.depositStatusPartiallyRefunded) {
    return 'Partial Deduction Approved';
  }
  if (request.depositStatus == AppConstants.depositStatusDeducted) {
    return 'Deposit Awarded to You';
  }
  return 'Admin Deposit Decision';
}

IconData _lenderAdminDecisionIcon(BorrowRequest request) {
  if (request.manualPayoutStatus == AppConstants.manualPayoutStatusPaid ||
      request.manualPayoutStatus ==
          AppConstants.manualPayoutStatusPendingManual) {
    return Icons.account_balance_wallet_outlined;
  }
  if (request.manualPayoutStatus == AppConstants.manualPayoutStatusBlocked) {
    return Icons.hourglass_top_rounded;
  }
  if (request.depositStatus == AppConstants.depositStatusRefunded) {
    return Icons.reply_rounded;
  }
  return Icons.verified_rounded;
}

String _lenderAdminDecisionMessage(BorrowRequest request) {
  final note = request.adminResolutionReason.trim();
  final suffix = note.isEmpty ? '' : ' Admin note: $note';
  if (request.depositStatus == AppConstants.depositStatusRefunded) {
    return 'Admin returned the deposit to the borrower. No deposit payout is due.$suffix';
  }
  if (request.depositStatus == AppConstants.depositStatusPartiallyRefunded) {
    return 'Admin approved ${_money(request.damageDeductionAmount)} for the damage deduction. ${_money(request.depositRefundAmount)} returns to the borrower.$suffix';
  }
  if (request.depositStatus == AppConstants.depositStatusDeducted) {
    return 'Admin awarded the deposit to you. The payout amount is shown below.$suffix';
  }
  if (request.manualPayoutStatus == AppConstants.manualPayoutStatusPaid) {
    final ref = request.manualPayoutReference.trim();
    return ref.isEmpty
        ? 'Admin marked your manual payout as paid.'
        : 'Admin marked your manual payout as paid. Reference: $ref';
  }
  if (request.manualPayoutStatus ==
      AppConstants.manualPayoutStatusPendingManual) {
    if (request.refundStatus == AppConstants.refundStatusPending) {
      return 'Your manual payout is ready for admin collection. The borrower refund may still be processing separately.';
    }
    return 'Your manual payout is ready. Please collect it from admin; admin will record the payout reference after payment.';
  }
  if (request.manualPayoutStatus == AppConstants.manualPayoutStatusBlocked) {
    if (request.depositStatus == AppConstants.depositStatusDisputed ||
        request.status == AppConstants.borrowStatusDisputed) {
      return 'Payout is blocked while the deposit dispute is under admin review.';
    }
    if (request.refundStatus == AppConstants.refundStatusFailed) {
      return 'Payout is blocked because the borrower refund failed. Admin review is required.';
    }
    return 'Payout is blocked until the deposit dispute or refund issue is resolved.';
  }
  return 'Admin decision details will appear here once the deposit is resolved.';
}

bool _isFourDigitCode(String value) {
  return RegExp(r'^\d{4}$').hasMatch(value.trim());
}

AppUser _borrowerFromRequest({
  required BorrowRequest request,
  required AppUser currentUser,
}) {
  final names = _splitName(request.borrowerName);
  final now = DateTime.now();
  return AppUser(
    uid: request.borrowerId,
    firstName: names.$1,
    lastName: names.$2,
    email: request.borrowerEmail,
    phoneNumber: request.borrowerPhoneNumber,
    emailVerified: true,
    phoneVerified: request.borrowerPhoneNumber.trim().isNotEmpty,
    role: AppConstants.roleResident,
    verificationStatus: request.borrowerVerified
        ? AppConstants.verificationVerified
        : AppConstants.verificationPending,
    profileImageUrl: '',
    communityId: currentUser.communityId,
    communityName: currentUser.communityName,
    unitNumber: '',
    reputationScore: request.borrowerReputationScore,
    totalReviews: 0,
    completedBorrowings: 0,
    completedLendings: 0,
    completedServices: 0,
    termsAccepted: true,
    locationVerified: true,
    createdAt: now,
    updatedAt: now,
  );
}

(String, String) _splitName(String fullName) {
  final clean = fullName.trim();
  if (clean.isEmpty) return ('Resident', '');
  final parts = clean.split(RegExp(r'\s+'));
  if (parts.length == 1) return (parts.first, '');
  return (parts.first, parts.skip(1).join(' '));
}

Future<String?> _showRejectReasonSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _RejectReasonSheet(),
  );
}

class _RejectReasonSheet extends StatefulWidget {
  const _RejectReasonSheet();

  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorText = 'Reason is required.');
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: context.residentOutline(),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Reject Request',
              style: TextStyle(
                color: context.appInk,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a short reason so the borrower understands your decision.',
              style: TextStyle(
                color: context.appMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: context
                  .residentInputDecoration(
                    label: 'Reason',
                    hint: 'Example: Item is unavailable that day',
                  )
                  .copyWith(errorText: _errorText),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SecondaryButton(
                    label: 'Cancel',
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DangerButton(
                    label: 'Reject',
                    icon: Icons.block_rounded,
                    onTap: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
