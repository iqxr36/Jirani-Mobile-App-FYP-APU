// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : marketplace_helpers.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_marketplace_view.dart';

void _showBorrowRequestSheet({
  required BuildContext context,
  required ItemModel item,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.residentScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _BorrowRequestSheet(item: item),
  );
}

AppUser _ownerFromRequest({
  required BorrowRequest request,
  required AppUser currentUser,
}) {
  final names = _splitName(request.ownerName);
  final now = DateTime.now();
  return AppUser(
    uid: request.ownerId,
    firstName: names.$1,
    lastName: names.$2,
    email: request.ownerEmail,
    phoneNumber: '',
    emailVerified: true,
    phoneVerified: true,
    role: AppConstants.roleResident,
    verificationStatus: AppConstants.verificationVerified,
    profileImageUrl: '',
    communityId: currentUser.communityId,
    communityName: currentUser.communityName,
    unitNumber: '',
    reputationScore: 0,
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

String _imageAt(ItemModel item, int index) {
  return index < item.imageUrls.length ? item.imageUrls[index] : '';
}

String _money(double? value) {
  final amount = value ?? 0;
  final text = amount % 1 == 0
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  return 'RM $text';
}

String _requestDateRange(BorrowRequest request) {
  final start = _shortDateFormat.format(request.requestedStartDate);
  final end = _shortDateFormat.format(request.expectedReturnDate);
  return start == end ? start : '$start - $end';
}

String _borrowerDepositMessage(BorrowRequest request) {
  if (!request.hasDeposit ||
      request.depositDecision == AppConstants.depositDecisionNotRequired) {
    return 'The transaction is complete. No deposit was required for this item.';
  }
  if (request.depositDecision == AppConstants.depositDecisionReturnDeposit) {
    final reason = request.adminResolutionReason.trim();
    final message =
        'Your ${_money(request.depositAmount ?? 0)} deposit has been released back to you.';
    return reason.isEmpty ? message : '$message Admin note: $reason';
  }
  if (request.depositDecision == AppConstants.depositDecisionPartialDeduction) {
    final deduction = request.minorDeductionAmount ?? 0;
    final returned = (request.depositAmount ?? 0) - deduction;
    return '${_money(deduction)} was deducted for the accepted minor issue. ${_money(returned < 0 ? 0 : returned)} returns to you.';
  }
  if (request.depositDecision == AppConstants.depositDecisionWithholdDeposit) {
    final reason = request.adminResolutionReason.trim();
    final message =
        'Admin resolved the dispute for the lender, so the refundable deposit was withheld.';
    return reason.isEmpty ? message : '$message Admin note: $reason';
  }
  return 'The lender reported an issue. Deposit release will wait for admin review.';
}

bool _hasAdminDepositDecision(BorrowRequest request) {
  return request.adminResolvedAt != null ||
      request.adminResolutionReason.trim().isNotEmpty ||
      request.damageDecision.startsWith('admin_');
}

String _adminDecisionTitle(BorrowRequest request) {
  if (request.refundStatus == AppConstants.refundStatusPending) {
    return 'Refund Processing';
  }
  if (request.refundStatus == AppConstants.refundStatusFailed) {
    return 'Refund Needs Review';
  }
  if (request.depositStatus == AppConstants.depositStatusRefunded) {
    return 'Deposit Returned';
  }
  if (request.depositStatus == AppConstants.depositStatusPartiallyRefunded) {
    return 'Partial Deduction Approved';
  }
  if (request.depositStatus == AppConstants.depositStatusDeducted) {
    return 'Deposit Awarded to Lender';
  }
  return 'Admin Deposit Decision';
}

IconData _adminDecisionIcon(BorrowRequest request) {
  if (request.refundStatus == AppConstants.refundStatusFailed ||
      request.depositStatus == AppConstants.depositStatusDeducted) {
    return Icons.report_problem_outlined;
  }
  if (request.refundStatus == AppConstants.refundStatusPending) {
    return Icons.hourglass_top_rounded;
  }
  return Icons.verified_rounded;
}

String _depositStatusLabel(BorrowRequest request) {
  switch (request.depositStatus) {
    case AppConstants.depositStatusHeld:
      return 'Held';
    case AppConstants.depositStatusRefunded:
      return 'Refunded';
    case AppConstants.depositStatusPartiallyRefunded:
      return 'Partially Refunded';
    case AppConstants.depositStatusDeducted:
      return 'Deducted';
    case AppConstants.depositStatusDisputed:
      return 'Disputed';
    case AppConstants.depositStatusRefundFailed:
      return 'Refund Failed';
    case AppConstants.depositStatusNotRequired:
      return 'No Deposit';
    default:
      return request.hasDeposit ? 'Pending' : 'No Deposit';
  }
}

String _manualPayoutStatusLabel(String status) {
  switch (status) {
    case AppConstants.manualPayoutStatusBlocked:
      return 'Blocked';
    case AppConstants.manualPayoutStatusPendingManual:
      return 'Ready';
    case AppConstants.manualPayoutStatusPaid:
      return 'Paid';
    case AppConstants.manualPayoutStatusCancelled:
      return 'Cancelled';
    default:
      return 'Not Ready';
  }
}

String _depositLedgerMessage(BorrowRequest request) {
  if (request.refundStatus == AppConstants.refundStatusPending) {
    return 'The payment provider is processing the deposit refund. The final result is confirmed shortly.';
  }
  if (request.refundStatus == AppConstants.refundStatusFailed) {
    final reason = request.refundFailureReason.trim();
    return reason.isEmpty
        ? 'The refund did not complete. Admin review is required.'
        : 'The refund did not complete. Reason: $reason';
  }
  if (request.depositStatus == AppConstants.depositStatusDisputed) {
    return 'The deposit is blocked while admin reviews the damage dispute.';
  }
  if (request.depositStatus == AppConstants.depositStatusPartiallyRefunded) {
    return '${_money(request.damageDeductionAmount)} was deducted and ${_money(request.depositRefundAmount)} is being returned to you.';
  }
  if (request.depositStatus == AppConstants.depositStatusDeducted) {
    return 'Admin resolved the deposit for the lender. No deposit refund is due.';
  }
  if (request.depositStatus == AppConstants.depositStatusRefunded) {
    return 'Your refundable deposit has been released.';
  }
  if (request.depositStatus == AppConstants.depositStatusHeld) {
    return 'Your deposit is held until the return is completed or reviewed.';
  }
  return request.hasDeposit
      ? 'Deposit settlement will update here after return.'
      : 'No refundable deposit was required for this item.';
}

String _manualPayoutMessage(BorrowRequest request) {
  switch (request.manualPayoutStatus) {
    case AppConstants.manualPayoutStatusPendingManual:
      if (request.refundStatus == AppConstants.refundStatusPending) {
        return 'Your payout is ready for admin collection. The borrower refund may still be processing separately.';
      }
      return 'Your payout is ready. Please collect it from admin; admin will record the payout reference after payment.';
    case AppConstants.manualPayoutStatusPaid:
      final ref = request.manualPayoutReference.trim();
      return ref.isEmpty
          ? 'Admin marked this payout as paid.'
          : 'Admin marked this payout as paid. Reference: $ref';
    case AppConstants.manualPayoutStatusBlocked:
      if (request.depositStatus == AppConstants.depositStatusDisputed ||
          request.status == AppConstants.borrowStatusDisputed) {
        return 'Payout is blocked while the deposit dispute is under admin review.';
      }
      if (request.refundStatus == AppConstants.refundStatusFailed) {
        return 'Payout is blocked because the borrower refund failed. Admin review is required.';
      }
      return 'Payout is blocked until the deposit dispute or refund issue is resolved.';
    default:
      return 'Payout becomes ready after return and deposit settlement.';
  }
}

String _categoryLabel(String category) {
  switch (category) {
    case AppConstants.itemCategoryTools:
      return 'Tools';
    case AppConstants.itemCategoryKitchen:
      return 'Kitchen';
    case AppConstants.itemCategoryElectronics:
      return 'Electronics';
    case AppConstants.itemCategoryCleaning:
      return 'Cleaning';
    case AppConstants.itemCategoryStudy:
      return 'Study';
    case AppConstants.itemCategoryEventItems:
      return 'Event Items';
    default:
      return 'Other';
  }
}

String _conditionLabel(String condition) {
  switch (condition) {
    case AppConstants.itemConditionNew:
      return 'New';
    case AppConstants.itemConditionGood:
      return 'Good condition';
    default:
      return 'Used';
  }
}

String _statusLabel(BorrowRequest request) {
  return borrowRequestStatusLabel(
    request.status,
    paymentComplete: MarketplaceBorrowFlow.isPaymentComplete(request),
  );
}

bool _isAfterApproval(String status) {
  return status == AppConstants.borrowStatusPickupReady ||
      status == AppConstants.borrowStatusActive ||
      status == AppConstants.borrowStatusHandedOver ||
      status == AppConstants.borrowStatusReturnSubmitted ||
      status == AppConstants.borrowStatusMinorIssuePending ||
      status == AppConstants.borrowStatusDisputed ||
      status == AppConstants.borrowStatusCompleted;
}
