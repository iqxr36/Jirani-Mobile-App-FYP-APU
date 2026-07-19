// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : borrow_request_disputes.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../borrow_request_service.dart';

mixin _BorrowRequestDisputeMixin on _BorrowRequestServiceBase, _BorrowRequestHandoverMixin {
  /// Marketplace dispute flow: lender reports minor damage and proposes a deposit deduction for borrower approval.
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

  /// Marketplace dispute flow: borrower accepts minor deduction/refund or declines to open an admin dispute.
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
      // Marketplace deposit: accepted minor damage resolves deposit with partial refund to borrower and deduction to lender.
      if (accepted && _hasCompletedManagedPayment(request)) {
        await _resolveMarketplaceDeposit(
          borrowRequestId: requestId,
          decision: AppConstants.depositResolutionPartialDeduction,
          damageDeductionAmount: request.minorDeductionAmount ?? 0,
          reason: request.minorIssueReason,
        );
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for borrow request access.',
        );
      }
      throw Exception(e.message ?? 'Failed to respond to minor issue.');
    }
  }

  /// Marketplace dispute flow: lender reports major damage/loss and creates an admin case before deposit money is released.
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

  /// Marketplace return flow: writes common completed-state fields before deposit resolution or review.
  void _addCompletionUpdates({
    required WriteBatch batch,
    required DocumentReference<Map<String, dynamic>> requestRef,
    required Map<String, dynamic> updates,
  }) {
    batch.update(requestRef, {
      'status': AppConstants.borrowStatusCompleted,
      'returnConfirmedAt': FieldValue.serverTimestamp(),
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      ...updates,
    });
    // Item availability and completion counters are updated server-side.
  }

  /// Marketplace dispute flow: creates the admin report document linked to a borrow request and evidence photo.
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

  /// Marketplace deposit flow: lender records a clean-return decision or routes withhold cases to admin dispute resolution.
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

      if (_hasCompletedManagedPayment(request)) {
        if (d == AppConstants.depositDecisionWithholdDeposit) {
          throw Exception(
            'Use the major damage dispute flow so admin can resolve the deposit.',
          );
        }
        await _resolveMarketplaceDeposit(
          borrowRequestId: requestId,
          decision: AppConstants.depositResolutionFullRefund,
          damageDeductionAmount: 0,
          reason: reason.trim(),
        );
        return;
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
}
