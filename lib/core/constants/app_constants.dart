class AppConstants {
  AppConstants._();

  static const String appName = 'Trust Community';

  // Roles
  static const String roleResident = 'resident';
  static const String roleCommunityAdmin = 'communityAdmin';
  static const String roleSystemAdmin = 'systemAdmin';

  // Verification statuses
  static const String verificationPending = 'pending';
  static const String verificationApproved = 'approved';
  static const String verificationRejected = 'rejected';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String itemsCollection = 'items';
  static const String communitiesCollection = 'communities';
  static const String verificationRequestsCollection = 'verificationRequests';
  static const String reportsCollection = 'reports';
  static const String reviewsCollection = 'reviews';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
}
