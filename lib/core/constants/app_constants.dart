class AppConstants {
  AppConstants._();

  static const String appName = 'Jirani';

  // Roles
  static const String roleResident = 'resident';
  static const String roleCommunityAdmin = 'communityAdmin';
  static const String roleSystemAdmin = 'systemAdmin';

  // Verification statuses (active values only; see AppUser.fromMap for legacy Firestore data)
  static const String verificationPending = 'pending';
  static const String verificationSubmitted = 'submitted';
  static const String verificationVerified = 'verified';
  static const String verificationRejected = 'rejected';

  /// Verification request document statuses ([verificationRequests] collection).
  /// Aligns with [verificationSubmitted] for the in-review state.
  static const String verificationRequestPending = 'pending';
  static const String verificationRequestCancelled = 'cancelled';

  /// OCR processing statuses for verification request documents.
  static const String ocrStatusPending = 'pending';
  static const String ocrStatusProcessing = 'processing';
  static const String ocrStatusCompleted = 'completed';
  static const String ocrStatusFailed = 'failed';

  /// Residency document kinds (stored on [VerificationRequest.documentType]).
  static const String documentTypeUtilityBill = 'utilityBill';
  static const String documentTypeTenancyAgreement = 'tenancyAgreement';
  static const String documentTypeAccessCard = 'accessCard';
  static const String documentTypeOtherProof = 'otherProof';

  /// Firebase Storage root folder for verification uploads (see storage rules).
  static const String storageVerificationDocumentsPath =
      'verification_documents';
  static const String storageResidentDocumentsPath = 'resident_documents';
  static const String storageItemImagesPath = 'item_images';

  /// Borrow request proof images: borrow_request_proofs/{requestId}/{uid}/...
  static const String storageBorrowRequestProofsPath = 'borrow_request_proofs';

  // Marketplace item categories
  static const String itemCategoryTools = 'tools';
  static const String itemCategoryKitchen = 'kitchen';
  static const String itemCategoryElectronics = 'electronics';
  static const String itemCategoryCleaning = 'cleaning';
  static const String itemCategoryStudy = 'study';
  static const String itemCategoryEventItems = 'eventItems';
  static const String itemCategoryOther = 'other';

  // Marketplace item conditions
  static const String itemConditionNew = 'new';
  static const String itemConditionGood = 'good';
  static const String itemConditionUsed = 'used';

  // Marketplace lending types
  static const String lendingTypeFree = 'free';
  static const String lendingTypeSmallFee = 'smallFee';
  static const String lendingTypeDepositRequired = 'depositRequired';
  static const String lendingTypeFeeAndDeposit = 'feeAndDeposit';

  // Marketplace item statuses
  static const String itemStatusAvailable = 'available';
  static const String itemStatusUnavailable = 'unavailable';
  static const String itemStatusBorrowed = 'borrowed';
  static const String itemStatusArchived = 'archived';

  // Firestore collections
  static const String adminsCollection = 'admins';
  static const String usersCollection = 'users';
  static const String itemsCollection = 'items';
  static const String communitiesCollection = 'communities';
  static const String verificationRequestsCollection = 'verificationRequests';
  static const String reportsCollection = 'reports';
  static const String borrowRequestsCollection = 'borrowRequests';
  static const String reviewsCollection = 'reviews';
  static const String servicesCollection = 'services';
  static const String serviceRequestsCollection = 'serviceRequests';
  static const String transactionsCollection = 'transactions';
  static const String chatsCollection = 'chats';

  /// Admin review statuses for extracted verification document data.
  static const String adminStatusProcessing = 'processing';
  static const String adminStatusPendingReview = 'pending_review';
  static const String adminStatusManualCheckRequired = 'manual_check_required';
  static const String adminStatusConfirmed = 'confirmed';
  static const String adminStatusRejected = 'rejected';
  static const String messagesCollection = 'messages';
  static const String notificationsCollection = 'notifications';
  static const String activityLogsCollection = 'activityLogs';

  // Activity log event types
  static const String activityVerificationApproved = 'verificationApproved';
  static const String activityVerificationRejected = 'verificationRejected';

  // Borrow request statuses (Phase 4–5)
  static const String borrowStatusPending = 'pending';
  static const String borrowStatusApproved = 'approved';
  static const String borrowStatusRejected = 'rejected';
  static const String borrowStatusCancelled = 'cancelled';
  static const String borrowStatusPickupReady = 'pickupReady';
  static const String borrowStatusHandedOver = 'handedOver';
  static const String borrowStatusActive = 'active';
  static const String borrowStatusReturnSubmitted = 'returnSubmitted';
  static const String borrowStatusCompleted = 'completed';

  /// Item condition at handover (owner selects).
  static const String borrowConditionBeforeExcellent = 'excellent';
  static const String borrowConditionBeforeGood = 'good';
  static const String borrowConditionBeforeFair = 'fair';
  static const String borrowConditionBeforeDamaged = 'damaged';

  /// Item condition at return (owner selects).
  static const String borrowConditionAfterSame = 'sameCondition';
  static const String borrowConditionAfterMinor = 'minorDamage';
  static const String borrowConditionAfterMajor = 'majorDamage';
  static const String borrowConditionAfterLost = 'lost';

  // Deposit decision (Phase 6)
  static const String depositDecisionNotRequired = 'notRequired';
  static const String depositDecisionPending = 'pending';
  static const String depositDecisionReturnDeposit = 'returnDeposit';
  static const String depositDecisionWithholdDeposit = 'withholdDeposit';

  // Reviews (Phase 6)
  static const String reviewRoleBorrowerToOwner = 'borrowerToOwner';
  static const String reviewRoleOwnerToBorrower = 'ownerToBorrower';

  // Reports / disputes (Phase 6)
  static const String reportTypeDamagedItem = 'damagedItem';
  static const String reportTypeLostItem = 'lostItem';
  static const String reportTypeDepositDispute = 'depositDispute';
  static const String reportTypeUserMisconduct = 'userMisconduct';
  static const String reportTypeOther = 'other';

  static const String reportStatusOpen = 'open';
  static const String reportStatusUnderReview = 'underReview';
  static const String reportStatusResolved = 'resolved';
  static const String reportStatusDismissed = 'dismissed';

  // Services catalog (Phase 6)
  static const String serviceCategoryCleaning = 'cleaning';
  static const String serviceCategoryTutoring = 'tutoring';
  static const String serviceCategoryRepair = 'repair';
  static const String serviceCategoryDelivery = 'delivery';
  static const String serviceCategoryPetCare = 'petCare';
  static const String serviceCategoryOther = 'other';

  static const String servicePriceTypeFree = 'free';
  static const String servicePriceTypeFixed = 'fixed';
  static const String servicePriceTypeNegotiable = 'negotiable';

  static const String serviceStatusActive = 'active';
  static const String serviceStatusInactive = 'inactive';
  static const String serviceStatusArchived = 'archived';

  static const String serviceRequestStatusPending = 'pending';
  static const String serviceRequestStatusAccepted = 'accepted';
  static const String serviceRequestStatusRejected = 'rejected';
  static const String serviceRequestStatusCancelled = 'cancelled';
  static const String serviceRequestStatusCompleted = 'completed';
}
