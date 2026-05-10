import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/data/models/app_user.dart';
import 'package:fyp_flutter_application/data/models/item_model.dart';
import 'package:fyp_flutter_application/models/borrow_request.dart';

class BorrowRequestService {
  BorrowRequestService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection(AppConstants.borrowRequestsCollection);

  Future<void> createBorrowRequest({
    required ItemModel item,
    required AppUser borrower,
    required DateTime requestedStartDate,
    required DateTime expectedReturnDate,
    required String pickupTime,
    required String message,
  }) async {
    if (borrower.uid == item.ownerId) {
      throw Exception('You cannot borrow your own item.');
    }
    if (!borrower.isVerifiedResident) {
      throw Exception('Only verified residents can submit borrow requests.');
    }
    if (item.status != AppConstants.itemStatusAvailable || item.isArchived) {
      throw Exception('This item is no longer available for borrowing.');
    }
    if (requestedStartDate.isAfter(expectedReturnDate)) {
      throw Exception('Invalid date range. Start date must be on or before return date.');
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != borrower.uid) {
      throw Exception('Missing user profile. Please sign in again.');
    }

    try {
      final duplicate = await _requests
          .where('itemId', isEqualTo: item.id)
          .where('borrowerId', isEqualTo: borrower.uid)
          .where('status', isEqualTo: AppConstants.borrowStatusPending)
          .limit(1)
          .get();
      if (duplicate.docs.isNotEmpty) {
        throw Exception('You already have a pending request for this item.');
      }

      final now = FieldValue.serverTimestamp();
      final doc = _requests.doc();
      await doc.set({
        'id': doc.id,
        'itemId': item.id,
        'itemTitle': item.title,
        'itemImageUrl': item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
        'ownerId': item.ownerId,
        'ownerName': item.ownerName,
        'ownerEmail': item.ownerEmail,
        'borrowerId': borrower.uid,
        'borrowerName': borrower.fullName,
        'borrowerEmail': borrower.email,
        'borrowerPhoneNumber': borrower.phoneNumber,
        'borrowerVerified': borrower.isVerifiedResident,
        'borrowerReputationScore': borrower.reputationScore.toDouble(),
        'requestedStartDate': Timestamp.fromDate(requestedStartDate),
        'expectedReturnDate': Timestamp.fromDate(expectedReturnDate),
        'pickupTime': pickupTime.trim(),
        'message': message.trim(),
        'status': AppConstants.borrowStatusPending,
        'usageFeeAmount': item.hasUsageFee ? item.feeAmount : null,
        'depositAmount': item.hasDeposit ? item.depositAmount : null,
        'hasUsageFee': item.hasUsageFee,
        'hasDeposit': item.hasDeposit,
        'createdAt': now,
        'updatedAt': now,
        'approvedAt': null,
        'rejectedAt': null,
        'rejectionReason': '',
        'pickupConfirmedAt': null,
        'handoverConfirmedAt': null,
        'returnSubmittedAt': null,
        'returnConfirmedAt': null,
        'completedAt': null,
        'pickupProofImageUrl': null,
        'handoverProofImageUrl': null,
        'returnProofImageUrl': null,
        'itemConditionBefore': null,
        'itemConditionAfter': null,
        'returnNotes': '',
        'ownerReturnNotes': '',
        'depositDecision': item.hasDeposit ? AppConstants.depositDecisionPending : AppConstants.depositDecisionNotRequired,
        'depositDecisionReason': '',
        'depositDecidedAt': null,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Check Firestore rules for borrow request access.');
      }
      throw Exception(e.message ?? 'Failed to create borrow request.');
    }
  }

  Stream<List<BorrowRequest>> watchMyBorrowRequests(String borrowerId) {
    return _requests.where('borrowerId', isEqualTo: borrowerId).snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => BorrowRequest.fromMap(doc.id, doc.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<BorrowRequest>> watchIncomingRequests(String ownerId) {
    return _requests.where('ownerId', isEqualTo: ownerId).snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => BorrowRequest.fromMap(doc.id, doc.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> approveBorrowRequest({
    required String requestId,
    required String ownerId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != ownerId) {
      throw Exception('Only the item owner can approve this request.');
    }
    try {
      final requestRef = _requests.doc(requestId);
      final snapshot = await requestRef.get();
      final data = snapshot.data();
      if (data == null) throw Exception('Borrow request not found.');
      final request = BorrowRequest.fromMap(snapshot.id, data);
      if (request.ownerId != ownerId) {
        throw Exception('Only the item owner can approve this request.');
      }
      if (request.status != AppConstants.borrowStatusPending) {
        throw Exception('Only pending requests can be approved.');
      }

      final batch = _firestore.batch();
      final itemRef = _firestore.collection(AppConstants.itemsCollection).doc(request.itemId);
      batch.update(requestRef, {
        'status': AppConstants.borrowStatusApproved,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(itemRef, {
        'status': AppConstants.itemStatusUnavailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final others = await _requests
          .where('itemId', isEqualTo: request.itemId)
          .where('status', isEqualTo: AppConstants.borrowStatusPending)
          .get();
      for (final doc in others.docs) {
        if (doc.id == requestId) continue;
        batch.update(doc.reference, {
          'status': AppConstants.borrowStatusRejected,
          'rejectionReason': 'Item was approved for another borrower.',
          'rejectedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Check Firestore rules for borrow request access.');
      }
      throw Exception(e.message ?? 'Failed to approve request.');
    }
  }

  Future<void> rejectBorrowRequest({
    required String requestId,
    required String ownerId,
    required String rejectionReason,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != ownerId) {
      throw Exception('Only the item owner can reject this request.');
    }
    if (rejectionReason.trim().isEmpty) {
      throw Exception('Rejection reason is required.');
    }
    try {
      final requestRef = _requests.doc(requestId);
      final snapshot = await requestRef.get();
      final data = snapshot.data();
      if (data == null) throw Exception('Borrow request not found.');
      final request = BorrowRequest.fromMap(snapshot.id, data);
      if (request.ownerId != ownerId) {
        throw Exception('Only the item owner can reject this request.');
      }
      if (request.status != AppConstants.borrowStatusPending) {
        throw Exception('Only pending requests can be rejected.');
      }
      await requestRef.update({
        'status': AppConstants.borrowStatusRejected,
        'rejectionReason': rejectionReason.trim(),
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Check Firestore rules for borrow request access.');
      }
      throw Exception(e.message ?? 'Failed to reject request.');
    }
  }

  Future<void> cancelBorrowRequest({
    required String requestId,
    required String borrowerId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != borrowerId) {
      throw Exception('Only the borrower can cancel this request.');
    }
    try {
      final requestRef = _requests.doc(requestId);
      final snapshot = await requestRef.get();
      final data = snapshot.data();
      if (data == null) throw Exception('Borrow request not found.');
      final request = BorrowRequest.fromMap(snapshot.id, data);
      if (request.borrowerId != borrowerId) {
        throw Exception('Only the borrower can cancel this request.');
      }
      if (request.status != AppConstants.borrowStatusPending) {
        throw Exception('Only pending requests can be cancelled.');
      }
      await requestRef.update({
        'status': AppConstants.borrowStatusCancelled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Check Firestore rules for borrow request access.');
      }
      throw Exception(e.message ?? 'Failed to cancel request.');
    }
  }

  Future<String?> _uploadProofImage({
    required String requestId,
    required String uid,
    required String localPath,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Proof image file not found.');
    }
    final fileName = localPath.split(RegExp(r'[/\\]')).last;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage
        .ref()
        .child(AppConstants.storageBorrowRequestProofsPath)
        .child(requestId)
        .child(uid)
        .child('${ts}_$fileName');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  /// Borrower: approved → pickupReady
  Future<void> confirmPickupReady({
    required String requestId,
    required String borrowerId,
    String? localProofPath,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != borrowerId) {
      throw Exception('Only the borrower can confirm pickup readiness.');
    }
    try {
      final requestRef = _requests.doc(requestId);
      final snapshot = await requestRef.get();
      final data = snapshot.data();
      if (data == null) throw Exception('Borrow request not found.');
      final request = BorrowRequest.fromMap(snapshot.id, data);
      if (request.borrowerId != borrowerId) {
        throw Exception('Only the borrower can confirm pickup readiness.');
      }
      if (request.status != AppConstants.borrowStatusApproved) {
        throw Exception('Pickup readiness can only be confirmed after approval.');
      }

      String? proofUrl;
      if (localProofPath != null && localProofPath.trim().isNotEmpty) {
        proofUrl = await _uploadProofImage(requestId: requestId, uid: borrowerId, localPath: localProofPath.trim());
      }

      await requestRef.update({
        'status': AppConstants.borrowStatusPickupReady,
        'pickupConfirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (proofUrl != null) 'pickupProofImageUrl': proofUrl,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Check Firestore rules for borrow request access.');
      }
      throw Exception(e.message ?? 'Failed to confirm pickup readiness.');
    }
  }

  /// Owner: pickupReady → active (handover)
  Future<void> confirmHandover({
    required String requestId,
    required String ownerId,
    required String conditionBefore,
    String? localProofPath,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != ownerId) {
      throw Exception('Only the item owner can confirm handover.');
    }
    final cond = conditionBefore.trim();
    if (cond.isEmpty) {
      throw Exception('Item condition before handover is required.');
    }
    final allowedBefore = {
      AppConstants.borrowConditionBeforeExcellent,
      AppConstants.borrowConditionBeforeGood,
      AppConstants.borrowConditionBeforeFair,
      AppConstants.borrowConditionBeforeDamaged,
    };
    if (!allowedBefore.contains(cond)) {
      throw Exception('Invalid condition before handover.');
    }

    try {
      final requestRef = _requests.doc(requestId);
      final snapshot = await requestRef.get();
      final data = snapshot.data();
      if (data == null) throw Exception('Borrow request not found.');
      final request = BorrowRequest.fromMap(snapshot.id, data);
      if (request.ownerId != ownerId) {
        throw Exception('Only the item owner can confirm handover.');
      }
      if (request.status != AppConstants.borrowStatusPickupReady) {
        throw Exception('Handover can only be confirmed when the borrower is ready for pickup.');
      }

      String? proofUrl;
      if (localProofPath != null && localProofPath.trim().isNotEmpty) {
        proofUrl = await _uploadProofImage(requestId: requestId, uid: ownerId, localPath: localProofPath.trim());
      }

      final batch = _firestore.batch();
      final itemRef = _firestore.collection(AppConstants.itemsCollection).doc(request.itemId);
      batch.update(requestRef, {
        'status': AppConstants.borrowStatusActive,
        'handoverConfirmedAt': FieldValue.serverTimestamp(),
        'itemConditionBefore': cond,
        'updatedAt': FieldValue.serverTimestamp(),
        if (proofUrl != null) 'handoverProofImageUrl': proofUrl,
      });
      batch.update(itemRef, {
        'status': AppConstants.itemStatusUnavailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Check Firestore rules for borrow request access.');
      }
      throw Exception(e.message ?? 'Failed to confirm handover.');
    }
  }

  /// Borrower: active → returnSubmitted
  Future<void> submitReturn({
    required String requestId,
    required String borrowerId,
    required String returnNotes,
    String? localProofPath,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != borrowerId) {
      throw Exception('Only the borrower can submit a return.');
    }
    try {
      final requestRef = _requests.doc(requestId);
      final snapshot = await requestRef.get();
      final data = snapshot.data();
      if (data == null) throw Exception('Borrow request not found.');
      final request = BorrowRequest.fromMap(snapshot.id, data);
      if (request.borrowerId != borrowerId) {
        throw Exception('Only the borrower can submit a return.');
      }
      final activeStatuses = {
        AppConstants.borrowStatusActive,
        AppConstants.borrowStatusHandedOver,
      };
      if (!activeStatuses.contains(request.status)) {
        throw Exception('Return can only be submitted during active borrowing.');
      }

      String? proofUrl;
      if (localProofPath != null && localProofPath.trim().isNotEmpty) {
        proofUrl = await _uploadProofImage(requestId: requestId, uid: borrowerId, localPath: localProofPath.trim());
      }

      await requestRef.update({
        'status': AppConstants.borrowStatusReturnSubmitted,
        'returnSubmittedAt': FieldValue.serverTimestamp(),
        'returnNotes': returnNotes.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (proofUrl != null) 'returnProofImageUrl': proofUrl,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Check Firestore rules for borrow request access.');
      }
      throw Exception(e.message ?? 'Failed to submit return.');
    }
  }

  /// Owner: returnSubmitted → completed; item → available
  Future<void> confirmReturn({
    required String requestId,
    required String ownerId,
    required String conditionAfter,
    required String ownerReturnNotes,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != ownerId) {
      throw Exception('Only the item owner can confirm return.');
    }
    final cond = conditionAfter.trim();
    if (cond.isEmpty) {
      throw Exception('Item condition after return is required.');
    }
    final allowedAfter = {
      AppConstants.borrowConditionAfterSame,
      AppConstants.borrowConditionAfterMinor,
      AppConstants.borrowConditionAfterMajor,
      AppConstants.borrowConditionAfterLost,
    };
    if (!allowedAfter.contains(cond)) {
      throw Exception('Invalid condition after return.');
    }

    try {
      final requestRef = _requests.doc(requestId);
      final snapshot = await requestRef.get();
      final data = snapshot.data();
      if (data == null) throw Exception('Borrow request not found.');
      final request = BorrowRequest.fromMap(snapshot.id, data);
      if (request.ownerId != ownerId) {
        throw Exception('Only the item owner can confirm return.');
      }
      if (request.status != AppConstants.borrowStatusReturnSubmitted) {
        throw Exception('Return confirmation is only available after the borrower submits return.');
      }

      final batch = _firestore.batch();
      final itemRef = _firestore.collection(AppConstants.itemsCollection).doc(request.itemId);
      batch.update(requestRef, {
        'status': AppConstants.borrowStatusCompleted,
        'returnConfirmedAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
        'itemConditionAfter': cond,
        'ownerReturnNotes': ownerReturnNotes.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'depositDecision': request.hasDeposit ? AppConstants.depositDecisionPending : AppConstants.depositDecisionNotRequired,
        'depositDecisionReason': '',
        'depositDecidedAt': null,
      });
      batch.update(itemRef, {
        'status': AppConstants.itemStatusAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Check Firestore rules for borrow request access.');
      }
      throw Exception(e.message ?? 'Failed to confirm return.');
    }
  }

  /// Owner sets deposit outcome after borrow completed (Phase 6).
  Future<void> setDepositDecision({
    required String requestId,
    required String ownerId,
    required String decision,
    String reason = '',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != ownerId) {
      throw Exception('Only the item owner can set deposit decision.');
    }
    final d = decision.trim();
    if (d != AppConstants.depositDecisionReturnDeposit && d != AppConstants.depositDecisionWithholdDeposit) {
      throw Exception('Invalid deposit decision.');
    }
    if (d == AppConstants.depositDecisionWithholdDeposit && reason.trim().isEmpty) {
      throw Exception('A reason is required when withholding the deposit.');
    }
    try {
      final requestRef = _requests.doc(requestId);
      final snapshot = await requestRef.get();
      final data = snapshot.data();
      if (data == null) throw Exception('Borrow request not found.');
      final request = BorrowRequest.fromMap(snapshot.id, data);
      if (request.ownerId != ownerId) {
        throw Exception('Only the item owner can set deposit decision.');
      }
      if (request.status != AppConstants.borrowStatusCompleted) {
        throw Exception('Deposit decision is only available after the borrow is completed.');
      }
      if (!request.hasDeposit) {
        throw Exception('This borrow request has no deposit.');
      }
      if (request.depositDecision != AppConstants.depositDecisionPending) {
        throw Exception('Deposit decision has already been recorded.');
      }

      final batch = _firestore.batch();
      batch.update(requestRef, {
        'depositDecision': d,
        'depositDecisionReason': d == AppConstants.depositDecisionWithholdDeposit ? reason.trim() : '',
        'depositDecidedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (d == AppConstants.depositDecisionWithholdDeposit) {
        final reportRef = _firestore.collection(AppConstants.reportsCollection).doc();
        batch.set(reportRef, {
          'type': AppConstants.reportTypeDepositDispute,
          'relatedBorrowRequestId': request.id,
          'itemId': request.itemId,
          'reporterId': ownerId,
          'reporterName': request.ownerName,
          'reportedUserId': request.borrowerId,
          'reportedUserName': request.borrowerName,
          'title': 'Deposit withheld',
          'description': reason.trim(),
          'status': AppConstants.reportStatusOpen,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Check Firestore rules for borrow request access.');
      }
      throw Exception(e.message ?? 'Failed to save deposit decision.');
    }
  }
}
