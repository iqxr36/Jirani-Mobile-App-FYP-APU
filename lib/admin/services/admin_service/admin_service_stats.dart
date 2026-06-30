part of '../admin_service.dart';

// Admin dashboard feature: calculates counts shown in overview cards.
mixin _AdminServiceStatsMixin on _AdminServiceBase {
  // Admin verification feature: loads users matching one verification status.
  Future<List<AppUser>> getUsersByVerificationStatus(String status) async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('verificationStatus', isEqualTo: status)
        .get();
    return snapshot.docs
        .map((d) => AppUser.fromMap(d.data()))
        .toList(growable: false);
  }

  // Admin dashboard feature: computes scoped counts for requests, residents, listings, and open reports.
  Future<Map<String, int>> getAdminDashboardStats({
    String? communityId,
    String? communityName,
    bool includeAllCommunities = false,
  }) async {
    final scopeCommunityId = (communityId ?? '').trim();
    final scopeCommunityName = (communityName ?? '').trim();
    if (!includeAllCommunities && scopeCommunityId.isEmpty) {
      return const <String, int>{
        'submittedRequests': 0,
        'verifiedResidents': 0,
        'rejectedRequests': 0,
        'totalUsers': 0,
        'activeListings': 0,
        'openReports': 0,
      };
    }

    Query<Map<String, dynamic>> verificationRequestsQuery = _firestore
        .collection(AppConstants.verificationRequestsCollection);
    Query<Map<String, dynamic>> usersQuery = _firestore.collection(
      AppConstants.usersCollection,
    );
    Query<Map<String, dynamic>> itemsQuery = _firestore.collection(
      AppConstants.itemsCollection,
    );
    Query<Map<String, dynamic>> reportsQuery = _firestore.collection(
      AppConstants.reportsCollection,
    );

    if (!includeAllCommunities) {
      verificationRequestsQuery = verificationRequestsQuery.where(
        'communityId',
        isEqualTo: scopeCommunityId,
      );
      usersQuery = usersQuery.where('communityId', isEqualTo: scopeCommunityId);
      itemsQuery = itemsQuery.where('communityId', isEqualTo: scopeCommunityId);
      reportsQuery = reportsQuery.where(
        'communityId',
        isEqualTo: scopeCommunityId,
      );
    }

    final verificationRequests = await verificationRequestsQuery.get();
    final totalUsers = await usersQuery.get();
    final items = await itemsQuery.get();
    final reports = await reportsQuery.get();

    bool inScope(Map<String, dynamic> data) {
      if (includeAllCommunities) return true;
      final itemCommunityId = (data['communityId'] as String?) ?? '';
      final itemCommunityName = (data['communityName'] as String?) ?? '';
      if (scopeCommunityId.isNotEmpty && itemCommunityId == scopeCommunityId) {
        return true;
      }
      if (scopeCommunityName.isNotEmpty &&
          itemCommunityName == scopeCommunityName) {
        return true;
      }
      return false;
    }

    int scopedCount(QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs.where((doc) => inScope(doc.data())).length;
    }

    return <String, int>{
      'submittedRequests': verificationRequests.docs.where((doc) {
        return inScope(doc.data()) &&
            doc.data()['status'] == AppConstants.verificationSubmitted;
      }).length,
      'verifiedResidents': totalUsers.docs.where((doc) {
        return inScope(doc.data()) &&
            doc.data()['verificationStatus'] ==
                AppConstants.verificationVerified;
      }).length,
      'rejectedRequests': verificationRequests.docs.where((doc) {
        return inScope(doc.data()) &&
            doc.data()['status'] == AppConstants.verificationRejected;
      }).length,
      'totalUsers': scopedCount(totalUsers),
      'activeListings': items.docs.where((doc) {
        final data = doc.data();
        return inScope(data) &&
            ((data['status'] as String?) == AppConstants.itemStatusAvailable ||
                (data['status'] as String?) ==
                    AppConstants.serviceStatusActive);
      }).length,
      'openReports': reports.docs.where((doc) {
        final data = doc.data();
        final status = (data['status'] as String?) ?? '';
        return inScope(data) &&
            (status.isEmpty ||
                status == AppConstants.reportStatusOpen ||
                status == AppConstants.reportStatusUnderReview);
      }).length,
    };
  }

  // Admin authentication feature: exposes the signed-in admin uid for audit fields.
  String? get currentAdminUid => _auth.currentUser?.uid;
}
