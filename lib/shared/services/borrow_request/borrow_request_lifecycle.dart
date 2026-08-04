// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : borrow_request_lifecycle.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../borrow_request_service.dart';

mixin _BorrowRequestLifecycleMixin on _BorrowRequestServiceBase {
  /// [Marketplace Rank 3 — BUSINESS LOGIC] Rechecks the item, borrower, dates, price, and deposit before writing the request.
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
      // Borrow request notifications are created server-side by Cloud Functions.
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
      }
      throw Exception(e.message ?? 'Failed to create borrow request.');
    }
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
      // Approval/rejection notifications are created server-side by Cloud Functions.
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
      // Rejection notifications are created server-side by Cloud Functions.
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
      if (request.status != AppConstants.borrowStatusPending && 
          !(request.status == AppConstants.borrowStatusApproved && request.paymentStatus == AppConstants.paymentStatusPending)) {
        throw Exception('Only pending or unpaid approved requests can be cancelled.');
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

}
