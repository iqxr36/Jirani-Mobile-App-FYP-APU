import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/models/verification_request.dart';
import 'package:jirani/shared/models/extracted_document_data.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/report_model.dart';
import 'package:jirani/shared/models/service_request_model.dart';
import 'package:jirani/shared/models/service_model.dart';

class AdminService {
  AdminService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

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

  Future<VerificationRequest?> getVerificationRequestById(
    String requestId,
  ) async {
    debugPrint('[AdminService][getById] requestId=$requestId');
    final doc = await _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .doc(requestId)
        .get();
    final data = doc.data();
    if (data == null) return null;
    final mapped = VerificationRequest.fromMap({...data, 'id': doc.id});
    debugPrint(
      '[AdminService][getById] mapped docId=${doc.id} requestId=${mapped.id} residentUid=${mapped.userId} status=${mapped.status}',
    );
    return mapped;
  }

  Future<void> approveVerificationRequest({
    required String requestId,
    required String residentUid,
    required String adminUid,
    ExtractedDocumentData? reviewedOcrData,
  }) async {
    if (requestId.trim().isEmpty) {
      throw Exception('Verification request ID is missing.');
    }
    if (residentUid.trim().isEmpty) {
      throw Exception(
        'Resident user ID is missing from this verification request.',
      );
    }
    if (adminUid.trim().isEmpty) {
      throw Exception('Admin user ID is missing.');
    }

    debugPrint(
      '[AdminService][approve] requestId=$requestId residentUid=$residentUid adminUid=$adminUid',
    );
    final batch = _firestore.batch();
    final requestRef = _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .doc(requestId);
    final userRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(residentUid);
    final logRef = _firestore
        .collection(AppConstants.activityLogsCollection)
        .doc();
    debugPrint('[AdminService][approve] requestRef=${requestRef.path}');
    debugPrint('[AdminService][approve] userRef=${userRef.path}');

    final requestUpdates = <String, dynamic>{
      'status': AppConstants.verificationVerified,
      'adminStatus': AppConstants.adminStatusConfirmed,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
      'rejectionReason': null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (reviewedOcrData != null) {
      requestUpdates.addAll(_reviewedOcrUpdates(reviewedOcrData, adminUid));
    }

    batch.update(requestRef, requestUpdates);
    batch.update(userRef, {
      'verificationStatus': AppConstants.verificationVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(logRef, {
      'type': AppConstants.activityVerificationApproved,
      'actorId': adminUid,
      'targetUserId': residentUid,
      'requestId': requestId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('[AdminService][approve] batch commit started');
    try {
      await batch.commit();
      debugPrint('Approve batch committed successfully');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore security rules for admin verification updates.',
        );
      }
      throw Exception(e.message ?? e.code);
    }
  }

  Map<String, dynamic> _reviewedOcrUpdates(
    ExtractedDocumentData data,
    String adminUid,
  ) {
    return <String, dynamic>{
      'documentType': data.type.name,
      'ocrText': data.fullText,
      'ocrFields': data.toFieldMap(),
      'extractedFields': _reviewedExtractedFields(data),
      'ocrStructuredData': data.toMap(),
      'ocrReviewedAt': FieldValue.serverTimestamp(),
      'ocrReviewedBy': adminUid,
    };
  }

  Future<void> rejectVerificationRequest({
    required String requestId,
    required String residentUid,
    required String adminUid,
    required String rejectionReason,
  }) async {
    if (requestId.trim().isEmpty) {
      throw Exception('Verification request ID is missing.');
    }
    if (residentUid.trim().isEmpty) {
      throw Exception(
        'Resident user ID is missing from this verification request.',
      );
    }
    if (adminUid.trim().isEmpty) {
      throw Exception('Admin user ID is missing.');
    }
    final reason = rejectionReason.trim();
    if (reason.isEmpty) {
      throw Exception('Rejection reason is required.');
    }

    debugPrint(
      '[AdminService][reject] requestId=$requestId residentUid=$residentUid adminUid=$adminUid reason="$reason"',
    );
    final batch = _firestore.batch();
    final requestRef = _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .doc(requestId);
    final userRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(residentUid);
    final logRef = _firestore
        .collection(AppConstants.activityLogsCollection)
        .doc();
    debugPrint('[AdminService][reject] requestRef=${requestRef.path}');
    debugPrint('[AdminService][reject] userRef=${userRef.path}');

    batch.update(requestRef, {
      'status': AppConstants.verificationRejected,
      'adminStatus': AppConstants.adminStatusRejected,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(userRef, {
      'verificationStatus': AppConstants.verificationRejected,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(logRef, {
      'type': AppConstants.activityVerificationRejected,
      'actorId': adminUid,
      'targetUserId': residentUid,
      'requestId': requestId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('[AdminService][reject] batch commit started');
    try {
      await batch.commit();
      debugPrint('Reject batch committed successfully');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore security rules for admin verification updates.',
        );
      }
      throw Exception(e.message ?? e.code);
    }
  }

  Map<String, dynamic> _reviewedExtractedFields(ExtractedDocumentData data) {
    final fields = <String, dynamic>{};
    void add(String key, String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) return;
      fields[key] = <String, dynamic>{
        'value': trimmed,
        'confidence': 1.0,
        'source': 'admin_review',
      };
    }

    add('tenant_name', data.tenantName);
    add('landlord_name', data.landlordName);
    add('unit_number', data.unitNumber);
    add('agreement_date', data.agreementDate);
    add('property_address', data.propertyAddress);
    return fields;
  }

  Future<List<AppUser>> getUsersByVerificationStatus(String status) async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('verificationStatus', isEqualTo: status)
        .get();
    return snapshot.docs
        .map((d) => AppUser.fromMap(d.data()))
        .toList(growable: false);
  }

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

  String? get currentAdminUid => _auth.currentUser?.uid;

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
