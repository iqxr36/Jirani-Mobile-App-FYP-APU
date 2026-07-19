// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_service_watchers.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../admin_service.dart';

// Admin realtime data feature: provides scoped streams for every collection shown in the portal.
mixin _AdminServiceWatchersMixin on _AdminServiceBase {
  // Admin verification feature: streams verification requests filtered by status and admin community scope.
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
            if (s.isNotEmpty && s != 'all') {
              if (s == AppConstants.verificationSubmitted) {
                if (!_needsAdminVerificationDecision(request)) return false;
              } else if (request.status != s) {
                return false;
              }
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

  // Admin verification feature: decides whether OCR/submitted request states still need admin review.
  bool _needsAdminVerificationDecision(VerificationRequest request) {
    if (request.status == AppConstants.verificationRejected ||
        request.status == AppConstants.verificationVerified) {
      return false;
    }
    if (request.status == AppConstants.verificationSubmitted ||
        request.status == AppConstants.verificationRequestPending) {
      return true;
    }
    if (request.adminStatus == AppConstants.adminStatusOcrMatched ||
        request.adminStatus == AppConstants.adminStatusManualCheckRequired ||
        request.adminStatus == AppConstants.adminStatusPendingReview ||
        request.adminStatus == AppConstants.adminStatusProcessing) {
      return true;
    }
    return false;
  }

  // Admin residents feature: streams resident users in the admin's assigned community.
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

  // Admin listings feature: streams marketplace items in the admin's assigned community.
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

  // Admin reports feature: streams complaint/report documents in the admin's assigned community.
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

  // Admin services feature: streams service listings; AdminProvider applies resident/community visibility.
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

  // Admin transactions feature: streams marketplace borrow requests for transaction/deposit review.
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

  // Admin services feature: streams service requests; AdminProvider applies community visibility.
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

  // Admin scoping feature: checks whether a record belongs to the selected admin community.
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
