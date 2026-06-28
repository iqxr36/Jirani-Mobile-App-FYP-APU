part of '../admin_service.dart';

mixin _AdminServiceResidentsMixin on _AdminServiceBase {
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
    final batch = _firestore.batch();
    final userRef = _residentRef(residentUid);
    final logRef = _activityLogRef();

    batch.update(userRef, {
      'firstName': trimmedFirstName,
      'lastName': trimmedLastName,
      'fullName': '$trimmedFirstName $trimmedLastName'.trim(),
      'phoneNumber': phoneNumber.trim(),
      'unitNumber': unitNumber.trim(),
      'communityId': communityId.trim(),
      'communityName': communityName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(logRef, _residentLogData(
      type: AppConstants.activityResidentUpdated,
      adminUid: adminUid,
      residentUid: residentUid,
    ));
    await batch.commit();
  }

  Future<void> suspendResident({
    required String residentUid,
    required String adminUid,
    required String reason,
  }) async {
    _requireResidentActionIds(residentUid: residentUid, adminUid: adminUid);
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw Exception('Suspension reason is required.');
    }
    final batch = _firestore.batch();
    batch.update(_residentRef(residentUid), {
      'accountStatus': AppConstants.accountStatusSuspended,
      'accountFlagged': true,
      'suspendedReason': trimmedReason,
      'suspendedAt': FieldValue.serverTimestamp(),
      'suspendedBy': adminUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_activityLogRef(), _residentLogData(
      type: AppConstants.activityResidentSuspended,
      adminUid: adminUid,
      residentUid: residentUid,
      reason: trimmedReason,
    ));
    await batch.commit();
  }

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
      'suspendedBy': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_activityLogRef(), _residentLogData(
      type: AppConstants.activityResidentReactivated,
      adminUid: adminUid,
      residentUid: residentUid,
    ));
    await batch.commit();
  }

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
    batch.set(_activityLogRef(), _residentLogData(
      type: AppConstants.activityResidentArchived,
      adminUid: adminUid,
      residentUid: residentUid,
      reason: trimmedReason,
    ));
    await batch.commit();
  }

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
    batch.set(_activityLogRef(), _residentLogData(
      type: AppConstants.activityResidentUnarchived,
      adminUid: adminUid,
      residentUid: residentUid,
    ));
    await batch.commit();
  }

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
    batch.set(_activityLogRef(), _residentLogData(
      type: AppConstants.activityResidentVerificationReset,
      adminUid: adminUid,
      residentUid: residentUid,
      reason: trimmedReason,
    ));
    await batch.commit();
  }

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
    batch.set(_activityLogRef(), _residentLogData(
      type: AppConstants.activityResidentVerificationOverridden,
      adminUid: adminUid,
      residentUid: residentUid,
      reason: trimmedReason,
      extra: {'status': nextStatus},
    ));
    await batch.commit();
  }

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
    batch.set(_activityLogRef(), _residentLogData(
      type: AppConstants.activityResidentNoticeSent,
      adminUid: adminUid,
      residentUid: residentUid,
      extra: {'title': trimmedTitle},
    ));
    await batch.commit();
  }

  DocumentReference<Map<String, dynamic>> _residentRef(String residentUid) {
    return _firestore.collection(AppConstants.usersCollection).doc(residentUid);
  }

  DocumentReference<Map<String, dynamic>> _activityLogRef() {
    return _firestore.collection(AppConstants.activityLogsCollection).doc();
  }

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
