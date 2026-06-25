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

String _categoryLabel(String category) {
  for (final option in _categoryOptions) {
    if (option.value == category) return option.label;
  }
  return 'Other';
}

String _conditionLabel(String condition) {
  for (final option in _conditionOptions) {
    if (option.value == condition) return option.label;
  }
  return 'Used';
}

String _handoverConditionLabel(String condition) {
  for (final option in _handoverConditionOptions) {
    if (option.value == condition) return option.label;
  }
  return condition.trim().isEmpty ? 'Not recorded' : condition;
}

String _returnConditionLabel(String condition) {
  for (final option in _returnConditionOptions) {
    if (option.value == condition) return option.label;
  }
  return condition.trim().isEmpty ? 'Not recorded' : condition;
}

String _depositDecisionLabel(String decision) {
  for (final option in _depositDecisionOptions) {
    if (option.value == decision) return option.label;
  }
  if (decision == AppConstants.depositDecisionNotRequired) {
    return 'No deposit required';
  }
  if (decision == AppConstants.depositDecisionPending) {
    return 'Pending decision';
  }
  if (decision == AppConstants.depositDecisionPartialDeduction) {
    return 'Partial deduction';
  }
  return decision.trim().isEmpty ? 'Not recorded' : decision;
}

String _statusLabel(ItemModel item) {
  if (item.isArchived || item.status == AppConstants.itemStatusArchived) {
    return 'Archived';
  }
  if (item.status == AppConstants.itemStatusAvailable) return 'Available';
  if (item.status == AppConstants.itemStatusUnavailable) return 'Unavailable';
  if (item.status == AppConstants.itemStatusBorrowed) return 'Borrowed';
  return item.status;
}

_StatusTone _itemStatusTone(ItemModel item) {
  if (item.isArchived || item.status == AppConstants.itemStatusArchived) {
    return _StatusTone.neutral;
  }
  if (item.status == AppConstants.itemStatusAvailable) {
    return _StatusTone.success;
  }
  return _StatusTone.warning;
}

bool _listingHasLiveBorrow(ItemModel item) {
  if (item.isArchived || item.status == AppConstants.itemStatusArchived) {
    return false;
  }
  return item.status != AppConstants.itemStatusAvailable;
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
  switch (request.status) {
    case AppConstants.borrowStatusPending:
      return 'Pending';
    case AppConstants.borrowStatusApproved:
      return MarketplaceBorrowFlow.isPaymentComplete(request)
          ? 'Paid'
          : 'Approved';
    case AppConstants.borrowStatusRejected:
      return 'Rejected';
    case AppConstants.borrowStatusCancelled:
      return 'Cancelled';
    case AppConstants.borrowStatusPickupReady:
      return 'Handover Started';
    case AppConstants.borrowStatusHandedOver:
    case AppConstants.borrowStatusActive:
      return 'Active';
    case AppConstants.borrowStatusReturnSubmitted:
      return 'Returning';
    case AppConstants.borrowStatusMinorIssuePending:
      return 'Minor Issue';
    case AppConstants.borrowStatusDisputed:
      return 'Disputed';
    case AppConstants.borrowStatusCompleted:
      return 'Completed';
    default:
      return request.status;
  }
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

Future<String?> _showRejectReasonSheet(BuildContext context) async {
  final controller = TextEditingController();
  String? errorText;
  try {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                      controller: controller,
                      minLines: 3,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                      decoration: context.residentInputDecoration(
                        label: 'Reason',
                        hint: 'Example: Item is unavailable that day',
                      ).copyWith(errorText: errorText),
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
                            onTap: () {
                              final reason = controller.text.trim();
                              if (reason.isEmpty) {
                                setSheetState(() {
                                  errorText = 'Reason is required.';
                                });
                                return;
                              }
                              Navigator.of(context).pop(reason);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
