part of '../admin_service.dart';

mixin _AdminServiceReportsMixin
    on _AdminServiceBase, _AdminServicePaymentsMixin {
  Future<void> resolveMarketplaceDispute({
    required String reportId,
    required String borrowRequestId,
    required String adminUid,
    required bool resolveForBorrower,
    required String reason,
  }) async {
    if (reportId.trim().isEmpty || borrowRequestId.trim().isEmpty) {
      throw Exception('Missing dispute report or transaction ID.');
    }
    if (adminUid.trim().isEmpty) {
      throw Exception('Admin user ID is missing.');
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw Exception('Resolution reason is required.');
    }

    final requestRef = _firestore
        .collection(AppConstants.borrowRequestsCollection)
        .doc(borrowRequestId.trim());
    final reportRef = _firestore
        .collection(AppConstants.reportsCollection)
        .doc(reportId.trim());
    final requestSnap = await requestRef.get();
    final requestData = requestSnap.data();
    if (requestData == null) {
      throw Exception('Borrow request not found.');
    }
    final request = BorrowRequest.fromMap(requestSnap.id, requestData);
    if (request.status != AppConstants.borrowStatusDisputed) {
      throw Exception('Only disputed transactions can be resolved by admin.');
    }

    if (request.paymentProvider == AppConstants.paymentProviderStripe &&
        request.paymentStatus == AppConstants.paymentStatusCompleted) {
      await resolveMarketplaceDeposit(
        borrowRequestId: borrowRequestId.trim(),
        decision: resolveForBorrower
            ? AppConstants.depositResolutionFullRefund
            : AppConstants.depositResolutionFullDeduction,
        damageDeductionAmount: resolveForBorrower
            ? 0
            : (request.depositAmount ?? 0),
        reason: trimmedReason,
        reportId: reportId.trim(),
      );
      return;
    }

    final resolution = resolveForBorrower
        ? AppConstants.adminResolutionForBorrower
        : AppConstants.adminResolutionForLender;
    final depositDecision = resolveForBorrower
        ? AppConstants.depositDecisionReturnDeposit
        : AppConstants.depositDecisionWithholdDeposit;

    final batch = _firestore.batch();
    batch.update(requestRef, {
      'status': AppConstants.borrowStatusCompleted,
      'returnConfirmedAt': FieldValue.serverTimestamp(),
      'completedAt': FieldValue.serverTimestamp(),
      'depositDecision': request.hasDeposit
          ? depositDecision
          : AppConstants.depositDecisionNotRequired,
      'depositDecisionReason': trimmedReason,
      'depositDecidedAt': FieldValue.serverTimestamp(),
      'adminResolution': resolution,
      'adminResolutionReason': trimmedReason,
      'adminResolvedAt': FieldValue.serverTimestamp(),
      'adminResolvedBy': adminUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(
      _firestore.collection(AppConstants.itemsCollection).doc(request.itemId),
      {
        'status': AppConstants.itemStatusAvailable,
        'lastCompletedBorrowRequestId': request.id,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.update(
      _firestore.collection(AppConstants.usersCollection).doc(request.ownerId),
      {
        'completedLendings': FieldValue.increment(1),
        'lastCompletedBorrowRequestId': request.id,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.update(
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(request.borrowerId),
      {
        'completedBorrowings': FieldValue.increment(1),
        'lastCompletedBorrowRequestId': request.id,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.update(reportRef, {
      'status': AppConstants.reportStatusResolved,
      'adminResolution': resolution,
      'adminResolutionReason': trimmedReason,
      'adminResolvedAt': FieldValue.serverTimestamp(),
      'adminResolvedBy': adminUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore security rules for admin dispute resolution.',
        );
      }
      throw Exception(e.message ?? e.code);
    }
  }

  Future<void> dismissReport({
    required String reportId,
    required String adminUid,
    required String reason,
  }) async {
    if (reportId.trim().isEmpty) {
      throw Exception('Report ID is missing.');
    }
    if (adminUid.trim().isEmpty) {
      throw Exception('Admin user ID is missing.');
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw Exception('Dismissal reason is required.');
    }

    try {
      await _firestore
          .collection(AppConstants.reportsCollection)
          .doc(reportId.trim())
          .update({
            'status': AppConstants.reportStatusDismissed,
            'dismissalReason': trimmedReason,
            'dismissedAt': FieldValue.serverTimestamp(),
            'dismissedBy': adminUid,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore security rules for report dismissal.',
        );
      }
      throw Exception(e.message ?? e.code);
    }
  }

  Future<void> issueUserWarningForReport({
    required String reportId,
    required String adminUid,
    required String message,
  }) async {
    if (reportId.trim().isEmpty) {
      throw Exception('Report ID is missing.');
    }
    if (adminUid.trim().isEmpty) {
      throw Exception('Admin user ID is missing.');
    }
    final warningMessage = message.trim();
    if (warningMessage.isEmpty) {
      throw Exception('Warning message is required.');
    }

    final reportRef = _firestore
        .collection(AppConstants.reportsCollection)
        .doc(reportId.trim());
    final reportSnap = await reportRef.get();
    final reportData = reportSnap.data();
    if (reportData == null) {
      throw Exception('Report not found.');
    }
    final reportedUserId = ((reportData['reportedUserId'] as String?) ?? '')
        .trim();
    if (reportedUserId.isEmpty) {
      throw Exception('This report has no reported user to warn.');
    }

    final notificationRef = _firestore
        .collection(AppConstants.notificationsCollection)
        .doc();
    final userRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(reportedUserId);
    final batch = _firestore.batch();
    batch.set(notificationRef, {
      'userId': reportedUserId,
      'type': 'adminWarning',
      'title': 'Community Trust Warning',
      'body': warningMessage,
      'category': 'Admin',
      'reportId': reportId.trim(),
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(reportRef, {
      'status': AppConstants.reportStatusUnderReview,
      'warningIssuedAt': FieldValue.serverTimestamp(),
      'warningIssuedBy': adminUid,
      'warningMessage': warningMessage,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(userRef, {
      'accountWarningCount': FieldValue.increment(1),
      'latestAdminWarningAt': FieldValue.serverTimestamp(),
      'latestAdminWarningMessage': warningMessage,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore security rules for admin warning notifications.',
        );
      }
      throw Exception(e.message ?? e.code);
    }
  }
}
