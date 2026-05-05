import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/data/models/app_user.dart';
import 'package:fyp_flutter_application/data/models/verification_request.dart';

class AdminService {
  AdminService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<List<VerificationRequest>> watchVerificationRequests({
    String? status,
  }) {
    Query<Map<String, dynamic>> q = _firestore.collection(AppConstants.verificationRequestsCollection);

    final s = (status ?? '').trim();
    if (s.isNotEmpty && s != 'all') {
      q = q.where('status', isEqualTo: s);
    }

    return q.snapshots().map((snapshot) {
      final requests = snapshot.docs
          .map((d) => VerificationRequest.fromMap({
                ...d.data(),
                'id': (d.data()['id'] as String?) ?? d.id,
              }))
          .toList();
      requests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return requests;
    });
  }

  Future<VerificationRequest?> getVerificationRequestById(String requestId) async {
    final doc = await _firestore.collection(AppConstants.verificationRequestsCollection).doc(requestId).get();
    final data = doc.data();
    if (data == null) return null;
    return VerificationRequest.fromMap({
      ...data,
      'id': (data['id'] as String?) ?? doc.id,
    });
  }

  Future<void> approveVerificationRequest({
    required String requestId,
    required String residentUid,
    required String adminUid,
  }) async {
    final batch = _firestore.batch();
    final requestRef = _firestore.collection(AppConstants.verificationRequestsCollection).doc(requestId);
    final userRef = _firestore.collection(AppConstants.usersCollection).doc(residentUid);
    final logRef = _firestore.collection(AppConstants.activityLogsCollection).doc();

    batch.update(requestRef, {
      'status': AppConstants.verificationVerified,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
      'rejectionReason': null,
    });
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

    await batch.commit();
  }

  Future<void> rejectVerificationRequest({
    required String requestId,
    required String residentUid,
    required String adminUid,
    required String rejectionReason,
  }) async {
    final batch = _firestore.batch();
    final requestRef = _firestore.collection(AppConstants.verificationRequestsCollection).doc(requestId);
    final userRef = _firestore.collection(AppConstants.usersCollection).doc(residentUid);
    final logRef = _firestore.collection(AppConstants.activityLogsCollection).doc();

    batch.update(requestRef, {
      'status': AppConstants.verificationRejected,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
      'rejectionReason': rejectionReason.trim(),
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
      'reason': rejectionReason.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<List<AppUser>> getUsersByVerificationStatus(String status) async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('verificationStatus', isEqualTo: status)
        .get();
    return snapshot.docs.map((d) => AppUser.fromMap(d.data())).toList(growable: false);
  }

  Future<Map<String, int>> getAdminDashboardStats() async {
    final submitted = await _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .where('status', isEqualTo: AppConstants.verificationSubmitted)
        .get();
    final verified = await _firestore
        .collection(AppConstants.usersCollection)
        .where('verificationStatus', isEqualTo: AppConstants.verificationVerified)
        .get();
    final rejected = await _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .where('status', isEqualTo: AppConstants.verificationRejected)
        .get();
    final totalUsers = await _firestore.collection(AppConstants.usersCollection).get();

    return <String, int>{
      'submittedRequests': submitted.docs.length,
      'verifiedResidents': verified.docs.length,
      'rejectedRequests': rejected.docs.length,
      'totalUsers': totalUsers.docs.length,
    };
  }

  String? get currentAdminUid => _auth.currentUser?.uid;
}
