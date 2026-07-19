// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_service_residents.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Monday,29-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../admin_service.dart';

// Admin residents feature: mutates resident account/profile status and records activity logs.
mixin _AdminServiceResidentsMixin on _AdminServiceBase {
  Future<void> clearDeletedResidentRestriction({
    required String residentUid,
  }) async {
    await _functions.httpsCallable('clearResidentEmailRestriction').call({
      'residentUid': residentUid,
    });
  }

  // Admin residents feature: updates resident profile and community assignment fields.
  Future<void> updateResidentDetails({
    required String residentUid,
    required String adminUid,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String unitNumber,
    required String communityId,
    required String communityName,
  }) async {
    _requireResidentActionIds(residentUid: residentUid, adminUid: adminUid);
    final trimmedFirstName = firstName.trim();
    final trimmedLastName = lastName.trim();
    if (trimmedFirstName.isEmpty || trimmedLastName.isEmpty) {
      throw Exception('Resident first and last name are required.');
    }
    final trimmedPhone = phoneNumber.trim();
    if (trimmedPhone.isNotEmpty) {
      await _functions.httpsCallable('adminUpdateResidentPhoneNumber').call({
        'residentUid': residentUid,
        'phoneNumber': trimmedPhone,
      });
    }
    final batch = _firestore.batch();
    final userRef = _residentRef(residentUid);
    final logRef = _activityLogRef();

    batch.update(userRef, {
      'firstName': trimmedFirstName,
      'lastName': trimmedLastName,
      'fullName': '$trimmedFirstName $trimmedLastName'.trim(),
      'unitNumber': unitNumber.trim(),
      'communityId': communityId.trim(),
      'communityName': communityName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      logRef,
      _residentLogData(
        type: AppConstants.activityResidentUpdated,
        adminUid: adminUid,
        residentUid: residentUid,
      ),
    );
    await batch.commit();
  }

  // Admin residents feature: suspends an account and records the suspension reason.
  Future<void> suspendResident({
    required String residentUid,
    required String adminUid,
    required String reason,
    required DateTime? suspensionEndsAt,
  }) async {
    _requireResidentActionIds(residentUid: residentUid, adminUid: adminUid);
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw Exception('Suspension reason is required.');
    }
    if (trimmedReason.length > 500) {
      throw Exception('Suspension reason cannot exceed 500 characters.');
    }
    if (suspensionEndsAt != null && !suspensionEndsAt.isAfter(DateTime.now())) {
      throw Exception('Suspension end time must be in the future.');
    }
    final batch = _firestore.batch();
    batch.update(_residentRef(residentUid), {
      'accountStatus': AppConstants.accountStatusSuspended,
      'accountFlagged': true,
      'suspendedReason': trimmedReason,
      'suspendedAt': FieldValue.serverTimestamp(),
      'suspensionEndsAt': suspensionEndsAt == null
          ? FieldValue.delete()
          : Timestamp.fromDate(suspensionEndsAt),
      'suspendedBy': adminUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _activityLogRef(),
      _residentLogData(
        type: AppConstants.activityResidentSuspended,
        adminUid: adminUid,
        residentUid: residentUid,
        reason: trimmedReason,
        extra: {
          'suspensionEndsAt': suspensionEndsAt == null
              ? null
              : Timestamp.fromDate(suspensionEndsAt),
        },
      ),
    );
    await batch.commit();
  }

  // Admin residents feature: reactivates a suspended account and clears suspension fields.
  Future<void> reactivateResident({
    required String residentUid,
    required String adminUid,
  }) async {
    _requireResidentActionIds(residentUid: residentUid, adminUid: adminUid);
    final batch = _firestore.batch();
    batch.update(_residentRef(residentUid), {
      'accountStatus': AppConstants.accountStatusActive,
      'accountFlagged': false,
      'suspendedReason': FieldValue.delete(),
      'suspendedAt': FieldValue.delete(),
      'suspensionEndsAt': FieldValue.delete(),
      'suspendedBy': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _activityLogRef(),
      _residentLogData(
        type: AppConstants.activityResidentReactivated,
        adminUid: adminUid,
        residentUid: residentUid,
      ),
    );
    await batch.commit();
  }

  // Admin residents feature: archives an account while keeping historical transactions/reports.
  Future<void> archiveResident({
    required String residentUid,
    required String adminUid,
    required String reason,
  }) async {
    _requireResidentActionIds(residentUid: residentUid, adminUid: adminUid);
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw Exception('Archive reason is required.');
    }
    final batch = _firestore.batch();
    batch.update(_residentRef(residentUid), {
      'accountStatus': AppConstants.accountStatusArchived,
      'accountFlagged': true,
      'archivedReason': trimmedReason,
      'archivedAt': FieldValue.serverTimestamp(),
      'archivedBy': adminUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _activityLogRef(),
      _residentLogData(
        type: AppConstants.activityResidentArchived,
        adminUid: adminUid,
        residentUid: residentUid,
        reason: trimmedReason,
      ),
    );
    await batch.commit();
  }

  // Admin residents feature: restores an archived account to active state.
  Future<void> unarchiveResident({
    required String residentUid,
    required String adminUid,
  }) async {
    _requireResidentActionIds(residentUid: residentUid, adminUid: adminUid);
    final batch = _firestore.batch();
    batch.update(_residentRef(residentUid), {
      'accountStatus': AppConstants.accountStatusActive,
      'accountFlagged': false,
      'archivedReason': FieldValue.delete(),
      'archivedAt': FieldValue.delete(),
      'archivedBy': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _activityLogRef(),
      _residentLogData(
        type: AppConstants.activityResidentUnarchived,
        adminUid: adminUid,
        residentUid: residentUid,
      ),
    );
    await batch.commit();
  }

  // Admin residents feature: resets verification to pending so the resident must submit proof again.
  Future<void> resetResidentVerification({
    required String residentUid,
    required String adminUid,
    required String reason,
  }) async {
    _requireResidentActionIds(residentUid: residentUid, adminUid: adminUid);
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw Exception('Reset reason is required.');
    }
    final batch = _firestore.batch();
    batch.update(_residentRef(residentUid), {
      'verificationStatus': AppConstants.verificationPending,
      'verificationResetReason': trimmedReason,
      'verificationResetAt': FieldValue.serverTimestamp(),
      'verificationResetBy': adminUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _activityLogRef(),
      _residentLogData(
        type: AppConstants.activityResidentVerificationReset,
        adminUid: adminUid,
        residentUid: residentUid,
        reason: trimmedReason,
      ),
    );
    await batch.commit();
  }

  // Admin residents feature: manually sets a resident verification status with an audit reason.
  Future<void> overrideResidentVerification({
    required String residentUid,
    required String adminUid,
    required String status,
    required String reason,
  }) async {
    _requireResidentActionIds(residentUid: residentUid, adminUid: adminUid);
    final trimmedReason = reason.trim();
    final nextStatus = status.trim();
    if (nextStatus != AppConstants.verificationVerified &&
        nextStatus != AppConstants.verificationRejected &&
        nextStatus != AppConstants.verificationPending) {
      throw Exception('Unsupported verification status.');
    }
    if (trimmedReason.isEmpty) {
      throw Exception('Verification override reason is required.');
    }
    final batch = _firestore.batch();
    batch.update(_residentRef(residentUid), {
      'verificationStatus': nextStatus,
      'verificationOverrideReason': trimmedReason,
      'verificationOverrideAt': FieldValue.serverTimestamp(),
      'verificationOverrideBy': adminUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _activityLogRef(),
      _residentLogData(
        type: AppConstants.activityResidentVerificationOverridden,
        adminUid: adminUid,
        residentUid: residentUid,
        reason: trimmedReason,
        extra: {'status': nextStatus},
      ),
    );
    await batch.commit();
  }

  // Admin residents feature: creates an admin notice notification for one resident.
  Future<void> sendResidentNotice({
    required String residentUid,
    required String adminUid,
    required String title,
    required String message,
  }) async {
    _requireResidentActionIds(residentUid: residentUid, adminUid: adminUid);
    final trimmedTitle = title.trim();
    final trimmedMessage = message.trim();
    if (trimmedTitle.isEmpty || trimmedMessage.isEmpty) {
      throw Exception('Notice title and message are required.');
    }
    final batch = _firestore.batch();
    batch.set(
      _firestore.collection(AppConstants.notificationsCollection).doc(),
      {
        'userId': residentUid,
        'type': AppConstants.notificationTypeAdminWarning,
        'title': trimmedTitle,
        'body': trimmedMessage,
        'category': 'Admin',
        'read': false,
        'actorId': adminUid,
        'residentId': residentUid,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    batch.set(
      _activityLogRef(),
      _residentLogData(
        type: AppConstants.activityResidentNoticeSent,
        adminUid: adminUid,
        residentUid: residentUid,
        extra: {'title': trimmedTitle},
      ),
    );
    await batch.commit();
  }

  // Admin residents feature: returns users/{uid} reference for resident account updates.
  DocumentReference<Map<String, dynamic>> _residentRef(String residentUid) {
    return _firestore.collection(AppConstants.usersCollection).doc(residentUid);
  }

  // Admin audit feature: creates a new activity log document reference.
  DocumentReference<Map<String, dynamic>> _activityLogRef() {
    return _firestore.collection(AppConstants.activityLogsCollection).doc();
  }

  // Admin residents feature: validates resident/admin IDs before any account mutation.
  void _requireResidentActionIds({
    required String residentUid,
    required String adminUid,
  }) {
    if (residentUid.trim().isEmpty) {
      throw Exception('Resident user ID is missing.');
    }
    if (adminUid.trim().isEmpty) {
      throw Exception('Admin user ID is missing.');
    }
  }

  // Admin audit feature: builds the activity log payload for resident account actions.
  Map<String, dynamic> _residentLogData({
    required String type,
    required String adminUid,
    required String residentUid,
    String reason = '',
    Map<String, dynamic> extra = const {},
  }) {
    return {
      'type': type,
      'actorId': adminUid,
      'targetUserId': residentUid,
      if (reason.trim().isNotEmpty) 'reason': reason.trim(),
      ...extra,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
