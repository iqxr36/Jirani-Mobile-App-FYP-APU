part of '../admin_service.dart';

mixin _AdminServiceWatchersMixin on _AdminServiceBase {
  Stream<List<VerificationRequest>> watchVerificationRequests({
    String? status,
    String? communityId,
    String? communityName,
    bool includeAllCommunities = false,
  }) {
    final scopeCommunityId = (communityId ?? '').trim();
    final scopeCommunityName = (communityName ?? '').trim();
    Query<Map<String, dynamic>> q = _firestore.collection(
      AppConstants.verificationRequestsCollection,
    );

    final s = (status ?? '').trim();
    if (!includeAllCommunities) {
      if (scopeCommunityId.isEmpty) {
        return Stream.value(const <VerificationRequest>[]);
      }
      q = q.where('communityId', isEqualTo: scopeCommunityId);
    } else if (s.isNotEmpty && s != 'all') {
      q = q.where('status', isEqualTo: s);
    }

    return q.snapshots().map((snapshot) {
      final requests = snapshot.docs
          .map((d) {
            final mapped = VerificationRequest.fromMap({
              ...d.data(),
              'id': d.id,
            });
            debugPrint(
              '[AdminService][watch] mapped docId=${d.id} requestId=${mapped.id} residentUid=${mapped.userId} status=${mapped.status}',
            );
            return mapped;
          })
          .where((request) {
            if (s.isNotEmpty && s != 'all' && request.status != s) {
              return false;
            }
            if (includeAllCommunities) return true;
            if (scopeCommunityId.isNotEmpty &&
                request.communityId == scopeCommunityId) {
              return true;
            }
            if (scopeCommunityName.isNotEmpty &&
                request.communityName == scopeCommunityName) {
              return true;
            }
            return false;
          })
          .toList();
      requests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return requests;
    });
  }

  Stream<List<AppUser>> watchResidents({
    String? communityId,
    String? communityName,
    bool includeAllCommunities = false,
  }) {
    final scopeCommunityId = (communityId ?? '').trim();
    if (!includeAllCommunities && scopeCommunityId.isEmpty) {
      return Stream.value(const <AppUser>[]);
    }

    Query<Map<String, dynamic>> q = _firestore.collection(
      AppConstants.usersCollection,
    );
    if (!includeAllCommunities) {
      q = q.where('communityId', isEqualTo: scopeCommunityId);
    }

    return q.snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
          .where((user) => user.role == AppConstants.roleResident)
          .where(
            (user) => _isInCommunityScope(
              communityId: user.communityId,
              communityName: user.communityName,
              scopeCommunityId: communityId,
              scopeCommunityName: communityName,
              includeAllCommunities: includeAllCommunities,
            ),
          )
          .toList();
      users.sort((a, b) => a.fullName.compareTo(b.fullName));
      return users;
    });
  }

  Stream<List<ItemModel>> watchListings({
    String? communityId,
    String? communityName,
    bool includeAllCommunities = false,
  }) {
    final scopeCommunityId = (communityId ?? '').trim();
    if (!includeAllCommunities && scopeCommunityId.isEmpty) {
      return Stream.value(const <ItemModel>[]);
    }

    Query<Map<String, dynamic>> q = _firestore.collection(
      AppConstants.itemsCollection,
    );
    if (!includeAllCommunities) {
      q = q.where('communityId', isEqualTo: scopeCommunityId);
    }

    return q.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => ItemModel.fromMap(doc.id, doc.data()))
          .where(
            (item) => _isInCommunityScope(
              communityId: item.communityId,
              communityName: item.communityName,
              scopeCommunityId: communityId,
              scopeCommunityName: communityName,
              includeAllCommunities: includeAllCommunities,
            ),
          )
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<ReportModel>> watchReports({
    String? communityId,
    bool includeAllCommunities = false,
  }) {
    final scopeCommunityId = (communityId ?? '').trim();
    if (!includeAllCommunities && scopeCommunityId.isEmpty) {
      return Stream.value(const <ReportModel>[]);
    }

    Query<Map<String, dynamic>> q = _firestore.collection(
      AppConstants.reportsCollection,
    );
    if (!includeAllCommunities) {
      q = q.where('communityId', isEqualTo: scopeCommunityId);
    }

    return q.snapshots().map((snapshot) {
      final reports = snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.id, doc.data()))
          .toList();
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  Stream<List<ServiceModel>> watchServices() {
    return _firestore
        .collection(AppConstants.servicesCollection)
        .snapshots()
        .map((snapshot) {
          final services = snapshot.docs
              .map((doc) => ServiceModel.fromMap(doc.id, doc.data()))
              .toList();
          services.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return services;
        });
  }

  Stream<List<BorrowRequest>> watchBorrowRequests() {
    return _firestore
        .collection(AppConstants.borrowRequestsCollection)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => BorrowRequest.fromMap(doc.id, doc.data()))
              .toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  Stream<List<ServiceRequestModel>> watchServiceRequests() {
    return _firestore
        .collection(AppConstants.serviceRequestsCollection)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => ServiceRequestModel.fromMap(doc.id, doc.data()))
              .toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  bool _isInCommunityScope({
    required String communityId,
    required String communityName,
    String? scopeCommunityId,
    String? scopeCommunityName,
    required bool includeAllCommunities,
  }) {
    if (includeAllCommunities) return true;
    final scopedId = (scopeCommunityId ?? '').trim();
    final scopedName = (scopeCommunityName ?? '').trim();
    if (scopedId.isNotEmpty && communityId.trim() == scopedId) return true;
    if (scopedName.isNotEmpty && communityName.trim() == scopedName) {
      return true;
    }
    return false;
  }
}
