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
  switch (request.status) {
    case AppConstants.borrowStatusPending:
      return 'Pending';
    case AppConstants.borrowStatusApproved:
      return MarketplaceBorrowFlow.isPaymentComplete(request)
          ? 'Paid'
          : 'Checkout';
    case AppConstants.borrowStatusRejected:
      return 'Rejected';
    case AppConstants.borrowStatusCancelled:
      return 'Cancelled';
    case AppConstants.borrowStatusPickupReady:
      return 'Handover';
    case AppConstants.borrowStatusActive:
    case AppConstants.borrowStatusHandedOver:
      return 'Active';
    case AppConstants.borrowStatusReturnSubmitted:
      return 'Returning';
    case AppConstants.borrowStatusMinorIssuePending:
      return 'Minor Issue';
    case AppConstants.borrowStatusDisputed:
      return 'Disputed';
    case AppConstants.borrowStatusCompleted:
      return 'Complete';
    default:
      return request.status;
  }
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
