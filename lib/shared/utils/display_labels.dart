import 'package:jirani/core/constants/app_constants.dart';

/// Human-readable labels for stored enum/status IDs shown in admin and resident UI.
/// Firestore keeps stable IDs; never show those raw values to end users.

const Map<String, String> _borrowRequestStatusLabels = {
  AppConstants.borrowStatusPending: 'Pending',
  AppConstants.borrowStatusApproved: 'Approved',
  AppConstants.borrowStatusRejected: 'Rejected',
  AppConstants.borrowStatusCancelled: 'Cancelled',
  AppConstants.borrowStatusPickupReady: 'Handover',
  AppConstants.borrowStatusHandedOver: 'Active',
  AppConstants.borrowStatusActive: 'Active',
  AppConstants.borrowStatusReturnSubmitted: 'Returning',
  AppConstants.borrowStatusMinorIssuePending: 'Minor Issue',
  AppConstants.borrowStatusDisputed: 'Disputed',
  AppConstants.borrowStatusCompleted: 'Completed',
};

const Map<String, String> _serviceRequestStatusLabels = {
  AppConstants.serviceRequestStatusPending: 'Pending',
  AppConstants.serviceRequestStatusAccepted: 'Accepted',
  AppConstants.serviceRequestStatusAcceptedAwaitingPayment: 'Awaiting Payment',
  AppConstants.serviceRequestStatusPaidHeld: 'Paid',
  AppConstants.serviceRequestStatusInProgress: 'In Progress',
  AppConstants.serviceRequestStatusCompletedPayoutPending: 'Payout Pending',
  AppConstants.serviceRequestStatusCompletedPayoutSent: 'Completed',
  AppConstants.serviceRequestStatusDisputed: 'Disputed',
  AppConstants.serviceRequestStatusRefunded: 'Refunded',
  AppConstants.serviceRequestStatusRejected: 'Rejected',
  AppConstants.serviceRequestStatusCancelled: 'Cancelled',
  AppConstants.serviceRequestStatusCompleted: 'Completed',
  AppConstants.serviceRequestStatusPaymentFailed: 'Payment Failed',
};

const Map<String, String> _paymentStatusLabels = {
  AppConstants.paymentStatusPending: 'Pending',
  AppConstants.paymentStatusCompleted: 'Completed',
  AppConstants.paymentStatusSucceeded: 'Succeeded',
  AppConstants.paymentStatusFailed: 'Failed',
  AppConstants.paymentStatusCancelled: 'Cancelled',
  AppConstants.paymentStatusRefunded: 'Refunded',
  AppConstants.paymentStatusFlowCancelled: 'Checkout Cancelled',
};

const Map<String, String> _refundStatusLabels = {
  AppConstants.refundStatusNotStarted: 'Not Started',
  AppConstants.refundStatusPending: 'Pending',
  AppConstants.refundStatusSucceeded: 'Succeeded',
  AppConstants.refundStatusFailed: 'Failed',
  AppConstants.refundStatusNotRequired: 'Not Required',
};

const Map<String, String> _depositStatusLabels = {
  AppConstants.depositStatusHeld: 'Held',
  AppConstants.depositStatusRefunded: 'Refunded',
  AppConstants.depositStatusPartiallyRefunded: 'Partially Refunded',
  AppConstants.depositStatusDeducted: 'Deducted',
  AppConstants.depositStatusDisputed: 'Disputed',
  AppConstants.depositStatusRefundFailed: 'Refund Failed',
  AppConstants.depositStatusNotRequired: 'Not Required',
};

const Map<String, String> _manualPayoutStatusLabels = {
  AppConstants.manualPayoutStatusNotReady: 'Not Ready',
  AppConstants.manualPayoutStatusBlocked: 'Blocked',
  AppConstants.manualPayoutStatusPendingManual: 'Awaiting Manual Payout',
  AppConstants.manualPayoutStatusPaid: 'Paid',
  AppConstants.manualPayoutStatusCancelled: 'Cancelled',
};

const Map<String, String> _servicePayoutStatusLabels = {
  AppConstants.servicePayoutStatusNotStarted: 'Not Started',
  AppConstants.servicePayoutStatusPending: 'Pending',
  AppConstants.servicePayoutStatusSent: 'Sent',
  AppConstants.servicePayoutStatusFailed: 'Failed',
  AppConstants.servicePayoutStatusBlocked: 'Blocked',
};

const Map<String, String> _itemStatusLabels = {
  AppConstants.itemStatusAvailable: 'Available',
  AppConstants.itemStatusUnavailable: 'Unavailable',
  AppConstants.itemStatusBorrowed: 'Borrowed',
  AppConstants.itemStatusArchived: 'Archived',
};

const Map<String, String> _itemCategoryLabels = {
  AppConstants.itemCategoryTools: 'Tools',
  AppConstants.itemCategoryKitchen: 'Kitchen',
  AppConstants.itemCategoryElectronics: 'Electronics',
  AppConstants.itemCategoryCleaning: 'Cleaning',
  AppConstants.itemCategoryStudy: 'Study',
  AppConstants.itemCategoryEventItems: 'Event Items',
  AppConstants.itemCategoryOther: 'Other',
};

const Map<String, String> _itemConditionLabels = {
  AppConstants.itemConditionNew: 'New',
  AppConstants.itemConditionGood: 'Good',
  AppConstants.itemConditionUsed: 'Used',
};

const Map<String, String> _serviceListingStatusLabels = {
  AppConstants.serviceStatusActive: 'Active',
  AppConstants.serviceStatusInactive: 'Inactive',
  AppConstants.serviceStatusArchived: 'Archived',
};

const Map<String, String> _serviceCategoryLabels = {
  AppConstants.serviceCategoryHomeCleaningUpkeep: 'Home Cleaning & Upkeep',
  AppConstants.serviceCategoryRepairsMaintenance: 'Repairs & Maintenance',
  AppConstants.serviceCategoryAssemblyLabor: 'Assembly & Labor',
  AppConstants.serviceCategoryTutoringEducation: 'Tutoring & Education',
  AppConstants.serviceCategoryAssistanceErrands: 'Assistance & Errands',
  AppConstants.serviceCategoryItTechSetup: 'IT & Tech Setup',
  AppConstants.serviceCategoryHomeCookingMealPrep: 'Home Cooking & Meal Prep',
  AppConstants.serviceCategoryCreativeDigitalTasks: 'Creative & Digital Tasks',
};

const Map<String, String> _verificationStatusLabels = {
  AppConstants.verificationPending: 'Pending',
  AppConstants.verificationSubmitted: 'Submitted',
  AppConstants.verificationVerified: 'Verified',
  AppConstants.verificationRejected: 'Rejected',
  AppConstants.verificationRequestCancelled: 'Cancelled',
};

const Map<String, String> _accountStatusLabels = {
  AppConstants.accountStatusActive: 'Active',
  AppConstants.accountStatusSuspended: 'Suspended',
  AppConstants.accountStatusArchived: 'Archived',
};

const Map<String, String> _reportTypeLabels = {
  AppConstants.reportTypeDamagedItem: 'Damaged Item',
  AppConstants.reportTypeLostItem: 'Lost Item',
  AppConstants.reportTypeDepositDispute: 'Deposit Dispute',
  AppConstants.reportTypeServiceDispute: 'Service Dispute',
  AppConstants.reportTypeUserMisconduct: 'User Misconduct',
  AppConstants.reportTypeOther: 'Other',
};

const Map<String, String> _reportStatusLabels = {
  AppConstants.reportStatusOpen: 'Open',
  AppConstants.reportStatusUnderReview: 'Under Review',
  AppConstants.reportStatusResolved: 'Resolved',
  AppConstants.reportStatusDismissed: 'Dismissed',
};

const Map<String, String> _lendingTypeLabels = {
  AppConstants.lendingTypeFree: 'Free',
  AppConstants.lendingTypeSmallFee: 'Small Fee',
  AppConstants.lendingTypeDepositRequired: 'Deposit Required',
  AppConstants.lendingTypeFeeAndDeposit: 'Fee & Deposit',
};

const Map<String, String> _servicePriceTypeLabels = {
  AppConstants.servicePriceTypeFree: 'Free',
  AppConstants.servicePriceTypeFixed: 'Fixed',
  AppConstants.servicePriceTypeNegotiable: 'Negotiable',
};

const Map<String, String> _servicePricingModeLabels = {
  AppConstants.servicePricingModeHourly: 'Hourly',
  AppConstants.servicePricingModeFixedJob: 'Fixed Job',
};

const Map<String, String> _depositDecisionLabels = {
  AppConstants.depositDecisionNotRequired: 'No Deposit Required',
  AppConstants.depositDecisionPending: 'Pending Decision',
  AppConstants.depositDecisionReturnDeposit: 'Return Deposit',
  AppConstants.depositDecisionPartialDeduction: 'Partial Deduction',
  AppConstants.depositDecisionWithholdDeposit: 'Withhold Deposit',
};

const Map<String, String> _damageDecisionLabels = {
  AppConstants.damageDecisionNone: 'None',
  AppConstants.damageDecisionBorrowerAccepted: 'Borrower Accepted',
  AppConstants.damageDecisionAdminFullRefund: 'Admin Full Refund',
  AppConstants.damageDecisionAdminPartialDeduction: 'Admin Partial Deduction',
  AppConstants.damageDecisionAdminFullDeduction: 'Admin Full Deduction',
};

const Map<String, String> _adminResolutionLabels = {
  AppConstants.adminResolutionPending: 'Pending',
  AppConstants.adminResolutionForBorrower: 'Resolved for Borrower',
  AppConstants.adminResolutionForLender: 'Resolved for Lender',
};

const Map<String, String> _settlementModeLabels = {
  AppConstants.settlementModeSimulated: 'Test Settlement',
  AppConstants.settlementModeLive: 'Live Settlement',
};

const Map<String, String> _payoutAccountStatusLabels = {
  AppConstants.payoutAccountStatusMissing: 'Missing',
  AppConstants.payoutAccountStatusPendingVerification: 'Pending Verification',
  AppConstants.payoutAccountStatusVerified: 'Verified',
  AppConstants.payoutAccountStatusRejected: 'Rejected',
};

const Map<String, String> _borrowHandoverConditionLabels = {
  AppConstants.borrowConditionBeforeExcellent: 'Excellent',
  AppConstants.borrowConditionBeforeGood: 'Good',
  AppConstants.borrowConditionBeforeFair: 'Fair',
  AppConstants.borrowConditionBeforeDamaged: 'Damaged',
};

const Map<String, String> _borrowReturnConditionLabels = {
  AppConstants.borrowConditionAfterSame: 'Same Condition',
  AppConstants.borrowConditionAfterMinor: 'Minor Damage',
  AppConstants.borrowConditionAfterMajor: 'Major Damage',
  AppConstants.borrowConditionAfterLost: 'Lost',
};

const Map<String, String> _ocrStatusLabels = {
  AppConstants.ocrStatusPending: 'Pending',
  AppConstants.ocrStatusProcessing: 'Processing',
  AppConstants.ocrStatusCompleted: 'Completed',
  AppConstants.ocrStatusFailed: 'Failed',
};

const Map<String, String> _connectionStatusLabels = {
  AppConstants.connectionPending: 'Pending',
  AppConstants.connectionAccepted: 'Accepted',
  AppConstants.connectionDeclined: 'Declined',
};

const Map<String, String> _communityPostTypeLabels = {
  AppConstants.communityPostTypeNews: 'News',
  AppConstants.communityPostTypeAnnouncement: 'Announcement',
  AppConstants.communityPostTypeWarning: 'Warning',
  AppConstants.communityPostTypeEvent: 'Event',
  AppConstants.communityPostTypeMaintenance: 'Maintenance',
};

const Map<String, String> _communityPostStatusLabels = {
  AppConstants.communityPostStatusDraft: 'Draft',
  AppConstants.communityPostStatusPublished: 'Published',
};

const Map<String, String> _reviewStatusLabels = {
  AppConstants.reviewStatusHidden: 'Hidden',
  AppConstants.reviewStatusPublished: 'Published',
};

const List<Map<String, String>> _displayLabelMaps = [
  _borrowRequestStatusLabels,
  _serviceRequestStatusLabels,
  _paymentStatusLabels,
  _refundStatusLabels,
  _depositStatusLabels,
  _manualPayoutStatusLabels,
  _servicePayoutStatusLabels,
  _itemStatusLabels,
  _itemCategoryLabels,
  _itemConditionLabels,
  _serviceListingStatusLabels,
  _serviceCategoryLabels,
  AppConstants.serviceDisputeTypeLabels,
  _verificationStatusLabels,
  _accountStatusLabels,
  _reportTypeLabels,
  _reportStatusLabels,
  _lendingTypeLabels,
  _servicePriceTypeLabels,
  _servicePricingModeLabels,
  _depositDecisionLabels,
  _damageDecisionLabels,
  _adminResolutionLabels,
  _settlementModeLabels,
  _payoutAccountStatusLabels,
  _borrowHandoverConditionLabels,
  _borrowReturnConditionLabels,
  _ocrStatusLabels,
  _connectionStatusLabels,
  _communityPostTypeLabels,
  _communityPostStatusLabels,
  _reviewStatusLabels,
];

String lookupDisplayLabel(String value) {
  final key = value.trim();
  if (key.isEmpty) return 'Unknown';
  for (final labels in _displayLabelMaps) {
    final match = labels[key];
    if (match != null) return match;
  }
  return formatUnknownDisplayLabel(key);
}

String formatUnknownDisplayLabel(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Unknown';

  final normalized = trimmed
      .replaceAll('_', ' ')
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      );

  return normalized
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map(
        (word) =>
            '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String borrowRequestStatusLabel(
  String status, {
  bool paymentComplete = false,
  bool lenderApprovedLabel = false,
}) {
  if (status == AppConstants.borrowStatusApproved) {
    if (paymentComplete) return 'Paid';
    if (lenderApprovedLabel) return 'Approved';
    return 'Checkout';
  }
  return _borrowRequestStatusLabels[status] ?? lookupDisplayLabel(status);
}

String serviceRequestStatusLabel(String status) =>
    _serviceRequestStatusLabels[status] ?? lookupDisplayLabel(status);

String paymentStatusLabel(String status) =>
    _paymentStatusLabels[status] ?? lookupDisplayLabel(status);

String refundStatusLabel(String status) =>
    _refundStatusLabels[status] ?? lookupDisplayLabel(status);

String depositStatusLabel(String status) =>
    _depositStatusLabels[status] ?? lookupDisplayLabel(status);

String manualPayoutStatusLabel(String status) =>
    _manualPayoutStatusLabels[status] ?? lookupDisplayLabel(status);

String servicePayoutStatusLabel(String status) =>
    _servicePayoutStatusLabels[status] ?? lookupDisplayLabel(status);

String itemStatusLabel(String status) =>
    _itemStatusLabels[status] ?? lookupDisplayLabel(status);

String itemCategoryLabel(String category) =>
    _itemCategoryLabels[category] ?? lookupDisplayLabel(category);

String itemConditionLabel(String condition) =>
    _itemConditionLabels[condition] ?? lookupDisplayLabel(condition);

String serviceListingStatusLabel(String status) =>
    _serviceListingStatusLabels[status] ?? lookupDisplayLabel(status);

String serviceCategoryLabel(String category) =>
    _serviceCategoryLabels[category] ?? lookupDisplayLabel(category);

String verificationStatusLabel(String status) =>
    _verificationStatusLabels[status] ?? lookupDisplayLabel(status);

String accountStatusLabel(String status) =>
    _accountStatusLabels[status] ?? lookupDisplayLabel(status);

String reportTypeLabel(String type) =>
    _reportTypeLabels[type] ?? lookupDisplayLabel(type);

String reportStatusLabel(String status) =>
    _reportStatusLabels[status] ?? lookupDisplayLabel(status);

String depositDecisionLabel(String decision) =>
    _depositDecisionLabels[decision] ?? lookupDisplayLabel(decision);

String adminResolutionLabel(String resolution) =>
    _adminResolutionLabels[resolution] ?? lookupDisplayLabel(resolution);

String serviceDisputeTypeLabel(String disputeType) =>
    AppConstants.serviceDisputeTypeLabel(disputeType);
