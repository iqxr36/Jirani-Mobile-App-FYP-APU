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

  // Resident account statuses
  static const String accountStatusActive = 'active';
  static const String accountStatusSuspended = 'suspended';
  static const String accountStatusArchived = 'archived';

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
  static const String storageProfileImagesPath = 'profile_images';

  /// Borrow request proof images: borrow_request_proofs/{requestId}/{uid}/...
  static const String storageBorrowRequestProofsPath = 'borrow_request_proofs';
  static const String storageChatAttachmentsPath = 'chat_attachments';
  static const String storageCommunityPostImagesPath = 'community_post_images';

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
  static const String publicProfilesCollection = 'publicProfiles';
  static const String itemsCollection = 'items';
  static const String communitiesCollection = 'communities';
  static const String verificationRequestsCollection = 'verificationRequests';
  static const String reportsCollection = 'reports';
  static const String borrowRequestsCollection = 'borrowRequests';
  static const String reviewsCollection = 'reviews';
  static const String servicesCollection = 'services';
  static const String serviceRequestsCollection = 'serviceRequests';
  static const String transactionsCollection = 'transactions';
  static const String paymentsCollection = 'payments';
  static const String paymentMethodsCollection = 'paymentMethods';
  static const String chatsCollection = 'chats';
  static const String connectionsCollection = 'connections';

  /// Admin review statuses for extracted verification document data.
  static const String adminStatusProcessing = 'processing';
  static const String adminStatusPendingReview = 'pending_review';
  static const String adminStatusManualCheckRequired = 'manual_check_required';
  static const String adminStatusConfirmed = 'confirmed';
  static const String adminStatusOcrMatched = 'ocr_matched';
  static const String adminStatusRejected = 'rejected';
  static const String messagesCollection = 'messages';
  static const String notificationsCollection = 'notifications';
  static const String communityPostsCollection = 'communityPosts';
  static const String activityLogsCollection = 'activityLogs';

  // Notification types
  static const String notificationTypeChatMessage = 'chatMessage';
  static const String notificationTypeAdminWarning = 'adminWarning';
  static const String notificationTypeConnectionRequest = 'connectionRequest';
  static const String notificationTypeConnectionAccepted =
      'connectionAccepted';
  static const String notificationTypeBorrowRequest = 'borrowRequest';
  static const String notificationTypeBorrowApproved = 'borrowApproved';
  static const String notificationTypeBorrowRejected = 'borrowRejected';
  static const String notificationTypeBorrowDepositResolved =
      'borrowDepositResolved';
  static const String notificationTypeBorrowPayoutReady = 'borrowPayoutReady';
  static const String notificationTypeBorrowPayoutPaid = 'borrowPayoutPaid';
  static const String notificationTypeServiceRequest = 'serviceRequest';
  static const String notificationTypeServiceAccepted = 'serviceAccepted';
  static const String notificationTypeServiceRejected = 'serviceRejected';
  static const String notificationTypeCommunityNews = 'communityNews';
  static const String notificationTypeCommunityEvent = 'communityEvent';
  static const String notificationTypeMaintenanceNotice = 'maintenanceNotice';
  static const String notificationTypeCommunityAnnouncement =
      'communityAnnouncement';
  static const String notificationTypeCommunityWarning = 'communityWarning';
  static const String notificationTypeVerificationOcrMatched =
      'verificationOcrMatched';
  static const String notificationTypeVerificationOcrReview =
      'verificationOcrReview';
  static const String notificationTypeAdminReport = 'adminReport';

  // Community post types and statuses
  static const String communityPostTypeNews = 'news';
  static const String communityPostTypeAnnouncement = 'announcement';
  static const String communityPostTypeWarning = 'warning';
  static const String communityPostTypeEvent = 'event';
  static const String communityPostTypeMaintenance = 'maintenance';
  static const String communityPostStatusDraft = 'draft';
  static const String communityPostStatusPublished = 'published';

  // Chat message types
  static const String chatMessageText = 'text';
  static const String chatMessageImage = 'image';
  static const String chatMessageFile = 'file';

  // Connections
  static const String connectionPending = 'pending';
  static const String connectionAccepted = 'accepted';
  static const String connectionDeclined = 'declined';

  // Activity log event types
  static const String activityVerificationApproved = 'verificationApproved';
  static const String activityVerificationRejected = 'verificationRejected';
  static const String activityResidentUpdated = 'residentUpdated';
  static const String activityResidentSuspended = 'residentSuspended';
  static const String activityResidentReactivated = 'residentReactivated';
  static const String activityResidentArchived = 'residentArchived';
  static const String activityResidentUnarchived = 'residentUnarchived';
  static const String activityResidentVerificationReset =
      'residentVerificationReset';
  static const String activityResidentVerificationOverridden =
      'residentVerificationOverridden';
  static const String activityResidentNoticeSent = 'residentNoticeSent';

  // Borrow request statuses (Phase 4–5)
  static const String borrowStatusPending = 'pending';
  static const String borrowStatusApproved = 'approved';
  static const String borrowStatusRejected = 'rejected';
  static const String borrowStatusCancelled = 'cancelled';
  static const String borrowStatusPickupReady = 'pickupReady';
  static const String borrowStatusHandedOver = 'handedOver';
  static const String borrowStatusActive = 'active';
  static const String borrowStatusReturnSubmitted = 'returnSubmitted';
  static const String borrowStatusMinorIssuePending = 'minorIssuePending';
  static const String borrowStatusDisputed = 'disputed';
  static const String borrowStatusCompleted = 'completed';

// Marketplace payments
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusCompleted = 'completed';
  static const String paymentStatusSucceeded = 'succeeded';
  static const String paymentStatusFailed = 'failed';
  static const String paymentStatusCancelled = 'cancelled';
  static const String paymentStatusRefunded = 'refunded';
  /// User left hosted checkout before provider confirmation.
  static const String paymentStatusFlowCancelled = 'flowCancelled';
  static const String paymentProviderManualV1 = 'manual_v1';
  static const String paymentProviderXendit = 'xendit';
  static const String paymentTypeMarketplace = 'marketplace';
  static const String paymentTypeService = 'service';
  static const String defaultPaymentCurrency = 'myr';

  // Marketplace deposit/refund ledger
  static const String depositStatusHeld = 'held';
  static const String depositStatusRefunded = 'refunded';
  static const String depositStatusPartiallyRefunded = 'partially_refunded';
  static const String depositStatusDeducted = 'deducted';
  static const String depositStatusDisputed = 'disputed';
  static const String depositStatusRefundFailed = 'refund_failed';
  static const String depositStatusNotRequired = 'not_required';

  static const String refundStatusNotStarted = 'not_started';
  static const String refundStatusPending = 'pending';
  static const String refundStatusSucceeded = 'succeeded';
  static const String refundStatusFailed = 'failed';
  static const String refundStatusNotRequired = 'not_required';

  static const String damageDecisionNone = 'none';
  static const String damageDecisionBorrowerAccepted = 'borrower_accepted';
  static const String damageDecisionAdminFullRefund = 'admin_full_refund';
  static const String damageDecisionAdminPartialDeduction =
      'admin_partial_deduction';
  static const String damageDecisionAdminFullDeduction =
      'admin_full_deduction';

  static const String manualPayoutStatusNotReady = 'not_ready';
  static const String manualPayoutStatusBlocked = 'blocked';
  static const String manualPayoutStatusPendingManual = 'pending_manual';
  static const String manualPayoutStatusPaid = 'paid';
  static const String manualPayoutStatusCancelled = 'cancelled';

  static const String depositResolutionFullRefund = 'full_refund';
  static const String depositResolutionPartialDeduction = 'partial_deduction';
  static const String depositResolutionFullDeduction = 'full_deduction';

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
  static const String depositDecisionPartialDeduction = 'partialDeduction';
  static const String depositDecisionWithholdDeposit = 'withholdDeposit';

  // Return inspection / dispute handling
  static const String minorIssueDecisionPending = 'pending';
  static const String minorIssueDecisionAccepted = 'accepted';
  static const String minorIssueDecisionDeclined = 'declined';
  static const String adminResolutionPending = 'pending';
  static const String adminResolutionForBorrower = 'resolveForBorrower';
  static const String adminResolutionForLender = 'resolveForLender';

  // Reviews (Phase 6)
  static const String reviewRoleBorrowerToOwner = 'borrowerToOwner';
  static const String reviewRoleOwnerToBorrower = 'ownerToBorrower';
  static const String reviewStatusHidden = 'hidden';
  static const String reviewStatusPublished = 'published';

  // Marketplace pricing
  static const String rentalModeDaily = 'daily';
  static const String rentalModeHourly = 'hourly';

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

  // Chat report categories
  static const String chatReportCategoryHarassment = 'harassment';
  static const String chatReportCategoryScam = 'scam';
  static const String chatReportCategoryThreat = 'threat';
  static const String chatReportCategorySpam = 'spam';
  static const String chatReportCategoryOther = 'other';

  static const List<String> chatReportCategories = [
    chatReportCategoryHarassment,
    chatReportCategoryScam,
    chatReportCategoryThreat,
    chatReportCategorySpam,
    chatReportCategoryOther,
  ];

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
