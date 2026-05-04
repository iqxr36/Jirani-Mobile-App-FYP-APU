class AppConstants {
  AppConstants._();

  static const String appName = 'Trust Community';

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

  /// Residency document kinds (stored on [VerificationRequest.documentType]).
  static const String documentTypeUtilityBill = 'utilityBill';
  static const String documentTypeTenancyAgreement = 'tenancyAgreement';
  static const String documentTypeAccessCard = 'accessCard';
  static const String documentTypeOtherProof = 'otherProof';

  /// Firebase Storage root folder for verification uploads (see storage rules).
  static const String storageVerificationDocumentsPath = 'verification_documents';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String itemsCollection = 'items';
  static const String communitiesCollection = 'communities';
  static const String verificationRequestsCollection = 'verificationRequests';
  static const String reportsCollection = 'reports';
  static const String reviewsCollection = 'reviews';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String notificationsCollection = 'notifications';
  static const String activityLogsCollection = 'activityLogs';
}
