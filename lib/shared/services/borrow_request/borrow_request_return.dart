part of '../borrow_request_service.dart';

mixin _BorrowRequestReturnMixin on _BorrowRequestServiceBase, _BorrowRequestHandoverMixin, _BorrowRequestDisputeMixin {
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
}
