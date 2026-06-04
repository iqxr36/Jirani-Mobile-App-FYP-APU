import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/models/borrow_request.dart';

class ReportService {
  ReportService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection(AppConstants.reportsCollection);

  CollectionReference<Map<String, dynamic>> get _borrowRequests =>
      _firestore.collection(AppConstants.borrowRequestsCollection);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  Future<void> createReport({
    required String type,
    required String relatedBorrowRequestId,
    required String itemId,
    required String reporterId,
    required String reporterName,
    required String reportedUserId,
    required String reportedUserName,
    required String title,
    required String description,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != reporterId) {
      throw Exception('Missing user profile. Please sign in again.');
    }
    final allowedTypes = {
      AppConstants.reportTypeDamagedItem,
      AppConstants.reportTypeLostItem,
      AppConstants.reportTypeDepositDispute,
      AppConstants.reportTypeUserMisconduct,
      AppConstants.reportTypeOther,
    };
    if (!allowedTypes.contains(type)) {
      throw Exception('Invalid report type.');
    }
    final t = title.trim();
    final d = description.trim();
    if (t.isEmpty || d.isEmpty) {
      throw Exception('Title and description are required.');
    }

    if (relatedBorrowRequestId.trim().isNotEmpty) {
      final brSnap = await _borrowRequests
          .doc(relatedBorrowRequestId.trim())
          .get();
      final brData = brSnap.data();
      if (brData == null) {
        throw Exception('Borrow request not found.');
      }
      final br = BorrowRequest.fromMap(brSnap.id, brData);
      if (br.status != AppConstants.borrowStatusCompleted) {
        throw Exception(
          'Reports can only be filed for completed borrow requests.',
        );
      }
      if (reporterId != br.borrowerId && reporterId != br.ownerId) {
        throw Exception('You are not a party to this borrow request.');
      }
      if (reportedUserId != br.borrowerId && reportedUserId != br.ownerId) {
        throw Exception(
          'Reported user must be the borrower or owner on this request.',
        );
      }
      if (reportedUserId == reporterId) {
        throw Exception('You cannot report yourself.');
      }
    }

    try {
      final reporterDoc = await _users.doc(reporterId).get();
      final reporterData = reporterDoc.data();
      if (reporterData == null) {
        throw Exception('Reporter profile not found.');
      }

      await _reports.add({
        'type': type,
        'relatedBorrowRequestId': relatedBorrowRequestId.trim(),
        'itemId': itemId,
        'communityId': (reporterData['communityId'] as String?) ?? '',
        'communityName': (reporterData['communityName'] as String?) ?? '',
        'reporterId': reporterId,
        'reporterName': reporterName,
        'reportedUserId': reportedUserId,
        'reportedUserName': reportedUserName,
        'title': t,
        'description': d,
        'status': AppConstants.reportStatusOpen,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for reports.',
        );
      }
      throw Exception(e.message ?? 'Failed to create report.');
    }
  }
}
