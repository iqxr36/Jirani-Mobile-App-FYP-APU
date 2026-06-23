import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/marketplace_borrow_flow.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/models/borrow_request.dart';

class BorrowRequestService {
  BorrowRequestService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection(AppConstants.borrowRequestsCollection);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection(AppConstants.itemsCollection);

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection(AppConstants.reportsCollection);

  Future<void> createBorrowRequest({
    required ItemModel item,
    required AppUser borrower,
    required DateTime requestedStartDate,
    required DateTime expectedReturnDate,
    required String pickupTime,
    required String message,
    double? usageFeeAmount,
    String rentalMode = '',
    int rentalUnitCount = 1,
    double? dailyRateSnapshot,
    double? hourlyRateSnapshot,
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
      throw Exception(
        'Invalid date range. Start date must be on or before return date.',
      );
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

      final resolvedRentalMode = rentalMode == AppConstants.rentalModeHourly
          ? AppConstants.rentalModeHourly
          : AppConstants.rentalModeDaily;
      final resolvedUnitCount = rentalUnitCount < 1 ? 1 : rentalUnitCount;
      final dailyRate = item.hasUsageFee ? item.feeAmount ?? 0 : null;
      final hourlyRate = item.hasUsageFee
          ? MarketplaceBorrowFlow.derivedHourlyRate(dailyRate ?? 0)
          : null;
      final resolvedUsageFee = item.hasUsageFee
          ? resolvedRentalMode == AppConstants.rentalModeHourly
                ? MarketplaceBorrowFlow.hourlyUsageFee(
                    dailyFee: dailyRate ?? 0,
                    hours: resolvedUnitCount,
                  )
                : MarketplaceBorrowFlow.dailyUsageFee(
                    dailyFee: dailyRate ?? 0,
                    start: requestedStartDate,
                    end: expectedReturnDate,
                  )
          : null;

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
        'paymentStatus': AppConstants.paymentStatusPending,
        'paymentCompletedAt': null,
        'paymentProvider': '',
        'chatId': '',
        'handoverCode': '',
        'returnCode': '',
        'usageFeeAmount': resolvedUsageFee,
        'depositAmount': item.hasDeposit ? item.depositAmount : null,
        'hasUsageFee': item.hasUsageFee,
        'hasDeposit': item.hasDeposit,
        'rentalMode': resolvedRentalMode,
        'rentalUnitCount': resolvedUnitCount,
        'dailyRateSnapshot': dailyRateSnapshot ?? dailyRate,
        'hourlyRateSnapshot': hourlyRateSnapshot ?? hourlyRate,
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
        'depositDecision': item.hasDeposit
            ? AppConstants.depositDecisionPending
            : AppConstants.depositDecisionNotRequired,
        'depositDecisionReason': '',
        'depositDecidedAt': null,
        'minorDeductionAmount': null,
        'minorIssueReason': '',
        'minorIssuePhotoUrl': null,
        'minorIssueReportedAt': null,
        'minorIssueBorrowerDecision': AppConstants.minorIssueDecisionPending,
        'minorIssueBorrowerRespondedAt': null,
        'disputeReportId': '',
        'disputeReason': '',
        'disputeEvidenceImageUrl': null,
        'disputeReportedAt': null,
        'adminResolution': AppConstants.adminResolutionPending,
        'adminResolutionReason': '',
        'adminResolvedAt': null,
        'adminResolvedBy': '',
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
      }
      throw Exception(e.message ?? 'Failed to create borrow request.');
    }
  }

  Stream<List<BorrowRequest>> watchMyBorrowRequests(String borrowerId) {
    return _requests.where('borrowerId', isEqualTo: borrowerId).snapshots().map(
      (snapshot) {
        final list = snapshot.docs
            .map((doc) => BorrowRequest.fromMap(doc.id, doc.data()))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  Stream<List<BorrowRequest>> watchIncomingRequests(String ownerId) {
    return _requests.where('ownerId', isEqualTo: ownerId).snapshots().map((
      snapshot,
    ) {
      final list = snapshot.docs
          .map((doc) => BorrowRequest.fromMap(doc.id, doc.data()))
          .toList();
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

      final others = await _requests
          .where('ownerId', isEqualTo: ownerId)
          .where('itemId', isEqualTo: request.itemId)
          .where('status', isEqualTo: AppConstants.borrowStatusPending)
          .get();

      final batch = _firestore.batch();
      final itemRef = _firestore
          .collection(AppConstants.itemsCollection)
          .doc(request.itemId);
      batch.update(requestRef, {
        'status': AppConstants.borrowStatusApproved,
        'paymentStatus': AppConstants.paymentStatusPending,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(itemRef, {
        'status': AppConstants.itemStatusUnavailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
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
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
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
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
      }
      throw Exception(e.message ?? 'Failed to cancel request.');
    }
  }

  Future<void> completeManualPayment({
    required String requestId,
    required String borrowerId,
    String chatId = '',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != borrowerId) {
      throw Exception('Only the borrower can complete this payment.');
    }

    try {
      final requestRef = _requests.doc(requestId);
      final snapshot = await requestRef.get();
      final data = snapshot.data();
      if (data == null) throw Exception('Borrow request not found.');
      final request = BorrowRequest.fromMap(snapshot.id, data);

      if (!MarketplaceBorrowFlow.canCompleteManualPayment(
        request: request,
        borrowerId: borrowerId,
      )) {
        throw Exception(
          'Payment is only available after the owner approves this request.',
        );
      }

      await requestRef.update({
        'paymentStatus': AppConstants.paymentStatusCompleted,
        'paymentCompletedAt': FieldValue.serverTimestamp(),
        'paymentProvider': AppConstants.paymentProviderManualV1,
        'chatId': chatId.trim().isEmpty
            ? _marketplaceChatId(request.borrowerId, request.ownerId)
            : chatId.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
      }
      throw Exception(e.message ?? 'Failed to complete payment.');
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

  /// Borrower: pickupReady → active after entering the lender's handover code.
  Future<void> confirmPickupReady({
    required String requestId,
    required String borrowerId,
    required String handoverCode,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != borrowerId) {
      throw Exception('Only the borrower can confirm pickup.');
    }
    try {
      final requestRef = _requests.doc(requestId);
      final snapshot = await requestRef.get();
      final data = snapshot.data();
      if (data == null) throw Exception('Borrow request not found.');
      final request = BorrowRequest.fromMap(snapshot.id, data);
      if (request.borrowerId != borrowerId) {
        throw Exception('Only the borrower can confirm pickup.');
      }
      if (request.status != AppConstants.borrowStatusPickupReady) {
        throw Exception(
          'Pickup can only be confirmed after the lender starts handover.',
        );
      }
      if (!MarketplaceBorrowFlow.isPaymentComplete(request)) {
        throw Exception('Complete payment before coordinating handover.');
      }
      final expectedCode = request.handoverCode.trim();
      if (expectedCode.isEmpty || handoverCode.trim() != expectedCode) {
        throw Exception('Invalid handover code.');
      }

      await requestRef.update({
        'status': AppConstants.borrowStatusActive,
        'handoverConfirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
      }
      throw Exception(e.message ?? 'Failed to confirm pickup.');
    }
  }

  /// Owner: approved → pickupReady by starting the in-person handover.
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
      if (request.status != AppConstants.borrowStatusApproved) {
        throw Exception(
          'Handover can only start after this request is approved.',
        );
      }
      if (!MarketplaceBorrowFlow.isPaymentComplete(request)) {
        throw Exception('Payment must be completed before handover.');
      }

      String? proofUrl;
      if (localProofPath != null && localProofPath.trim().isNotEmpty) {
        proofUrl = await _uploadProofImage(
          requestId: requestId,
          uid: ownerId,
          localPath: localProofPath.trim(),
        );
      }

      final batch = _firestore.batch();
      batch.update(requestRef, {
        'status': AppConstants.borrowStatusPickupReady,
        'pickupConfirmedAt': FieldValue.serverTimestamp(),
        'handoverCode': request.handoverCode.trim().isEmpty
            ? MarketplaceBorrowFlow.generateFourDigitCode()
            : request.handoverCode,
        'itemConditionBefore': cond,
        'updatedAt': FieldValue.serverTimestamp(),
        'handoverProofImageUrl': ?proofUrl,
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
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
        throw Exception(
          'Return can only be submitted during active borrowing.',
        );
      }

      String? proofUrl;
      if (localProofPath != null && localProofPath.trim().isNotEmpty) {
        proofUrl = await _uploadProofImage(
          requestId: requestId,
          uid: borrowerId,
          localPath: localProofPath.trim(),
        );
      }

      await requestRef.update({
        'status': AppConstants.borrowStatusReturnSubmitted,
        'returnSubmittedAt': FieldValue.serverTimestamp(),
        'returnNotes': returnNotes.trim(),
        'returnCode': request.returnCode.trim().isEmpty
            ? MarketplaceBorrowFlow.generateFourDigitCode()
            : request.returnCode,
        'updatedAt': FieldValue.serverTimestamp(),
        'returnProofImageUrl': ?proofUrl,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
      }
      throw Exception(e.message ?? 'Failed to submit return.');
    }
  }

  /// Owner happy path: returnSubmitted -> completed; item -> available.
  Future<void> confirmReturn({
    required String requestId,
    required String ownerId,
    required String conditionAfter,
    required String ownerReturnNotes,
    String returnCode = '',
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
    };
    if (!allowedAfter.contains(cond)) {
      throw Exception(
        'Use the minor issue or major damage flow when the item is not returned in the same condition.',
      );
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
        throw Exception(
          'Return confirmation is only available after the borrower submits return.',
        );
      }
      final expectedCode = request.returnCode.trim();
      if (expectedCode.isNotEmpty && returnCode.trim() != expectedCode) {
        throw Exception('Invalid return code.');
      }

      final batch = _firestore.batch();
      _addCompletionUpdates(
        batch: batch,
        requestRef: requestRef,
        request: request,
        updates: {
          'itemConditionAfter': cond,
          'ownerReturnNotes': ownerReturnNotes.trim(),
          'depositDecision': request.hasDeposit
              ? AppConstants.depositDecisionReturnDeposit
              : AppConstants.depositDecisionNotRequired,
          'depositDecisionReason': '',
          'depositDecidedAt': request.hasDeposit
              ? FieldValue.serverTimestamp()
              : null,
        },
      );
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
      }
      throw Exception(e.message ?? 'Failed to confirm return.');
    }
  }

  /// Owner reports minor damage and waits for the borrower to accept/decline.
  Future<void> reportMinorIssue({
    required String requestId,
    required String ownerId,
    required double deductionAmount,
    required String reason,
    String? localProofPath,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != ownerId) {
      throw Exception('Only the item owner can report a minor issue.');
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw Exception('A reason is required for a minor issue.');
    }

    try {
      final requestRef = _requests.doc(requestId);
      final snapshot = await requestRef.get();
      final data = snapshot.data();
      if (data == null) throw Exception('Borrow request not found.');
      final request = BorrowRequest.fromMap(snapshot.id, data);
      if (request.ownerId != ownerId) {
        throw Exception('Only the item owner can report a minor issue.');
      }
      if (request.status != AppConstants.borrowStatusReturnSubmitted) {
        throw Exception('Minor issues can only be reported during return.');
      }
      if (!request.hasDeposit || (request.depositAmount ?? 0) <= 0) {
        throw Exception('This request has no refundable deposit.');
      }
      final deposit = request.depositAmount ?? 0;
      if (deductionAmount <= 0 || deductionAmount >= deposit) {
        throw Exception(
          'Deduction must be more than RM 0 and less than the deposit.',
        );
      }

      String? proofUrl;
      if (localProofPath != null && localProofPath.trim().isNotEmpty) {
        proofUrl = await _uploadProofImage(
          requestId: requestId,
          uid: ownerId,
          localPath: localProofPath.trim(),
        );
      }

      await requestRef.update({
        'status': AppConstants.borrowStatusMinorIssuePending,
        'itemConditionAfter': AppConstants.borrowConditionAfterMinor,
        'ownerReturnNotes': trimmedReason,
        'minorDeductionAmount': deductionAmount,
        'minorIssueReason': trimmedReason,
        'minorIssuePhotoUrl': ?proofUrl,
        'minorIssueReportedAt': FieldValue.serverTimestamp(),
        'minorIssueBorrowerDecision': AppConstants.minorIssueDecisionPending,
        'minorIssueBorrowerRespondedAt': null,
        'depositDecision': AppConstants.depositDecisionPending,
        'depositDecisionReason': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
      }
      throw Exception(e.message ?? 'Failed to report minor issue.');
    }
  }

  /// Borrower accepts or declines the lender's minor deduction request.
  Future<void> respondToMinorIssue({
    required String requestId,
    required String borrowerId,
    required bool accepted,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != borrowerId) {
      throw Exception('Only the borrower can respond to the minor issue.');
    }

    try {
      final requestRef = _requests.doc(requestId);
      final snapshot = await requestRef.get();
      final data = snapshot.data();
      if (data == null) throw Exception('Borrow request not found.');
      final request = BorrowRequest.fromMap(snapshot.id, data);
      if (request.borrowerId != borrowerId) {
        throw Exception('Only the borrower can respond to the minor issue.');
      }
      if (request.status != AppConstants.borrowStatusMinorIssuePending) {
        throw Exception('There is no minor issue awaiting your response.');
      }

      final batch = _firestore.batch();
      if (accepted) {
        _addCompletionUpdates(
          batch: batch,
          requestRef: requestRef,
          request: request,
          updates: {
            'minorIssueBorrowerDecision':
                AppConstants.minorIssueDecisionAccepted,
            'minorIssueBorrowerRespondedAt': FieldValue.serverTimestamp(),
            'depositDecision': AppConstants.depositDecisionPartialDeduction,
            'depositDecisionReason': request.minorIssueReason,
            'depositDecidedAt': FieldValue.serverTimestamp(),
          },
        );
      } else {
        final borrowerDoc = await _users.doc(request.borrowerId).get();
        final borrowerData = borrowerDoc.data();
        final reportRef = _reports.doc();
        _setDisputeReport(
          batch: batch,
          reportRef: reportRef,
          request: request,
          communityId: (borrowerData?['communityId'] as String?) ?? '',
          communityName: (borrowerData?['communityName'] as String?) ?? '',
          reporterId: request.borrowerId,
          reporterName: request.borrowerName,
          reportedUserId: request.ownerId,
          reportedUserName: request.ownerName,
          title: 'Minor damage declined by borrower',
          description:
              '${request.minorIssueReason}\nRequested deduction: RM ${(request.minorDeductionAmount ?? 0).toStringAsFixed(2)}.',
          evidenceImageUrl: request.minorIssuePhotoUrl,
        );
        batch.update(requestRef, {
          'status': AppConstants.borrowStatusDisputed,
          'minorIssueBorrowerDecision':
              AppConstants.minorIssueDecisionDeclined,
          'minorIssueBorrowerRespondedAt': FieldValue.serverTimestamp(),
          'disputeReportId': reportRef.id,
          'disputeReason': request.minorIssueReason,
          'disputeEvidenceImageUrl': request.minorIssuePhotoUrl.trim().isEmpty
              ? null
              : request.minorIssuePhotoUrl,
          'disputeReportedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
      }
      throw Exception(e.message ?? 'Failed to respond to minor issue.');
    }
  }

  /// Owner reports major damage/loss and creates an admin dispute ticket.
  Future<void> reportMajorDamage({
    required String requestId,
    required String ownerId,
    required String conditionAfter,
    required String description,
    required String localProofPath,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != ownerId) {
      throw Exception('Only the item owner can report major damage.');
    }
    final cond = conditionAfter.trim();
    if (cond != AppConstants.borrowConditionAfterMajor &&
        cond != AppConstants.borrowConditionAfterLost) {
      throw Exception('Choose major damage or lost item for escalation.');
    }
    final trimmedDescription = description.trim();
    if (trimmedDescription.isEmpty) {
      throw Exception('A description is required for admin review.');
    }
    if (localProofPath.trim().isEmpty) {
      throw Exception('Photo evidence is required for major damage.');
    }

    try {
      final requestRef = _requests.doc(requestId);
      final snapshot = await requestRef.get();
      final data = snapshot.data();
      if (data == null) throw Exception('Borrow request not found.');
      final request = BorrowRequest.fromMap(snapshot.id, data);
      if (request.ownerId != ownerId) {
        throw Exception('Only the item owner can report major damage.');
      }
      if (request.status != AppConstants.borrowStatusReturnSubmitted) {
        throw Exception('Major damage can only be reported during return.');
      }

      final proofUrl =
          await _uploadProofImage(
            requestId: requestId,
            uid: ownerId,
            localPath: localProofPath.trim(),
          ) ??
          '';
      final ownerDoc = await _users.doc(ownerId).get();
      final ownerData = ownerDoc.data();
      final reportRef = _reports.doc();
      final batch = _firestore.batch();
      _setDisputeReport(
        batch: batch,
        reportRef: reportRef,
        request: request,
        communityId: (ownerData?['communityId'] as String?) ?? '',
        communityName: (ownerData?['communityName'] as String?) ?? '',
        reporterId: ownerId,
        reporterName: request.ownerName,
        reportedUserId: request.borrowerId,
        reportedUserName: request.borrowerName,
        title: cond == AppConstants.borrowConditionAfterLost
            ? 'Lost item dispute'
            : 'Major damage dispute',
        description: trimmedDescription,
        evidenceImageUrl: proofUrl,
      );
      batch.update(requestRef, {
        'status': AppConstants.borrowStatusDisputed,
        'itemConditionAfter': cond,
        'ownerReturnNotes': trimmedDescription,
        'disputeReportId': reportRef.id,
        'disputeReason': trimmedDescription,
        'disputeEvidenceImageUrl': proofUrl,
        'disputeReportedAt': FieldValue.serverTimestamp(),
        'depositDecision': AppConstants.depositDecisionPending,
        'depositDecisionReason': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
      }
      throw Exception(e.message ?? 'Failed to report major damage.');
    }
  }

  void _addCompletionUpdates({
    required WriteBatch batch,
    required DocumentReference<Map<String, dynamic>> requestRef,
    required BorrowRequest request,
    required Map<String, dynamic> updates,
  }) {
    batch.update(requestRef, {
      'status': AppConstants.borrowStatusCompleted,
      'returnConfirmedAt': FieldValue.serverTimestamp(),
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      ...updates,
    });
    batch.update(_items.doc(request.itemId), {
      'status': AppConstants.itemStatusAvailable,
      'lastCompletedBorrowRequestId': request.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_users.doc(request.ownerId), {
      'completedLendings': FieldValue.increment(1),
      'lastCompletedBorrowRequestId': request.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_users.doc(request.borrowerId), {
      'completedBorrowings': FieldValue.increment(1),
      'lastCompletedBorrowRequestId': request.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _setDisputeReport({
    required WriteBatch batch,
    required DocumentReference<Map<String, dynamic>> reportRef,
    required BorrowRequest request,
    required String communityId,
    required String communityName,
    required String reporterId,
    required String reporterName,
    required String reportedUserId,
    required String reportedUserName,
    required String title,
    required String description,
    required String evidenceImageUrl,
  }) {
    batch.set(reportRef, {
      'type': AppConstants.reportTypeDepositDispute,
      'relatedBorrowRequestId': request.id,
      'itemId': request.itemId,
      'communityId': communityId,
      'communityName': communityName,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'title': title,
      'description': description,
      'evidenceImageUrl': evidenceImageUrl.trim().isEmpty
          ? null
          : evidenceImageUrl.trim(),
      'depositAmount': request.depositAmount,
      'minorDeductionAmount': request.minorDeductionAmount,
      'status': AppConstants.reportStatusOpen,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
    if (d != AppConstants.depositDecisionReturnDeposit &&
        d != AppConstants.depositDecisionWithholdDeposit) {
      throw Exception('Invalid deposit decision.');
    }
    if (d == AppConstants.depositDecisionWithholdDeposit &&
        reason.trim().isEmpty) {
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
        throw Exception(
          'Deposit decision is only available after the borrow is completed.',
        );
      }
      if (!request.hasDeposit) {
        throw Exception('This borrow request has no deposit.');
      }
      if (request.depositDecision != AppConstants.depositDecisionPending) {
        throw Exception('Deposit decision has already been recorded.');
      }

      final ownerDoc = await _users.doc(ownerId).get();
      final ownerData = ownerDoc.data();
      if (ownerData == null) {
        throw Exception('Owner profile not found.');
      }

      final batch = _firestore.batch();
      batch.update(requestRef, {
        'depositDecision': d,
        'depositDecisionReason':
            d == AppConstants.depositDecisionWithholdDeposit
            ? reason.trim()
            : '',
        'depositDecidedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (d == AppConstants.depositDecisionWithholdDeposit) {
        final reportRef = _firestore
            .collection(AppConstants.reportsCollection)
            .doc();
        batch.set(reportRef, {
          'type': AppConstants.reportTypeDepositDispute,
          'relatedBorrowRequestId': request.id,
          'itemId': request.itemId,
          'communityId': (ownerData['communityId'] as String?) ?? '',
          'communityName': (ownerData['communityName'] as String?) ?? '',
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
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
      }
      throw Exception(e.message ?? 'Failed to save deposit decision.');
    }
  }

  static String _marketplaceChatId(String borrowerId, String ownerId) {
    final ids = <String>[borrowerId, ownerId]..sort();
    return ids.join('_');
  }
}
