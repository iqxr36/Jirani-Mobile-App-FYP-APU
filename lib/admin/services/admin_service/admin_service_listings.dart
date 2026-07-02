part of '../admin_service.dart';

// Admin listings feature: moderates marketplace items and task services while preserving audit history.
mixin _AdminServiceListingsMixin on _AdminServiceBase {
  Future<void> archiveMarketplaceItem({
    required String itemId,
    required String adminUid,
    required String reason,
  }) async {
    await _moderateListing(
      collection: AppConstants.itemsCollection,
      listingId: itemId,
      adminUid: adminUid,
      ownerField: 'ownerId',
      ownerNameField: 'ownerName',
      listingType: 'marketplaceItem',
      archivedStatus: AppConstants.itemStatusArchived,
      activityType: AppConstants.activityListingArchived,
      reason: reason,
      extraUpdates: const {'isArchived': true},
      notificationTitle: 'Listing removed by admin',
      notificationBody:
          'Your marketplace listing was removed from resident search by admin.',
    );
  }

  Future<void> restoreMarketplaceItem({
    required String itemId,
    required String adminUid,
    required String reason,
  }) async {
    final activeStatuses = {
      AppConstants.borrowStatusPending,
      AppConstants.borrowStatusApproved,
      AppConstants.borrowStatusPickupReady,
      AppConstants.borrowStatusHandedOver,
      AppConstants.borrowStatusActive,
      AppConstants.borrowStatusReturnSubmitted,
      AppConstants.borrowStatusMinorIssuePending,
      AppConstants.borrowStatusDisputed,
    };
    final activeBorrow = await _firestore
        .collection(AppConstants.borrowRequestsCollection)
        .where('itemId', isEqualTo: itemId.trim())
        .limit(20)
        .get();
    final hasActiveBorrow = activeBorrow.docs.any((doc) {
      final status = (doc.data()['status'] as String?) ?? '';
      return activeStatuses.contains(status);
    });
    if (hasActiveBorrow) {
      throw Exception(
        'This item has an active borrow request and cannot be restored yet.',
      );
    }

    await _moderateListing(
      collection: AppConstants.itemsCollection,
      listingId: itemId,
      adminUid: adminUid,
      ownerField: 'ownerId',
      ownerNameField: 'ownerName',
      listingType: 'marketplaceItem',
      archivedStatus: AppConstants.itemStatusAvailable,
      activityType: AppConstants.activityListingRestored,
      reason: reason,
      extraUpdates: {
        'isArchived': false,
      },
      clearModerationFields: true,
      notificationTitle: 'Listing restored by admin',
      notificationBody:
          'Your marketplace listing is visible to residents again.',
    );
  }

  Future<void> archiveTaskService({
    required String serviceId,
    required String adminUid,
    required String reason,
  }) async {
    await _moderateListing(
      collection: AppConstants.servicesCollection,
      listingId: serviceId,
      adminUid: adminUid,
      ownerField: 'providerId',
      ownerNameField: 'providerName',
      listingType: 'taskService',
      archivedStatus: AppConstants.serviceStatusArchived,
      activityType: AppConstants.activityListingArchived,
      reason: reason,
      notificationTitle: 'Service removed by admin',
      notificationBody:
          'Your task service was removed from resident search by admin.',
    );
  }

  Future<void> restoreTaskService({
    required String serviceId,
    required String adminUid,
    required String reason,
  }) async {
    await _moderateListing(
      collection: AppConstants.servicesCollection,
      listingId: serviceId,
      adminUid: adminUid,
      ownerField: 'providerId',
      ownerNameField: 'providerName',
      listingType: 'taskService',
      archivedStatus: AppConstants.serviceStatusActive,
      activityType: AppConstants.activityListingRestored,
      reason: reason,
      clearModerationFields: true,
      notificationTitle: 'Service restored by admin',
      notificationBody: 'Your task service is visible to residents again.',
    );
  }

  Future<void> _moderateListing({
    required String collection,
    required String listingId,
    required String adminUid,
    required String ownerField,
    required String ownerNameField,
    required String listingType,
    required String archivedStatus,
    required String activityType,
    required String reason,
    required String notificationTitle,
    required String notificationBody,
    Map<String, dynamic> extraUpdates = const {},
    bool clearModerationFields = false,
  }) async {
    final trimmedListingId = listingId.trim();
    final trimmedAdminUid = adminUid.trim();
    final trimmedReason = reason.trim();
    if (trimmedListingId.isEmpty) {
      throw Exception('Listing ID is missing.');
    }
    if (trimmedAdminUid.isEmpty) {
      throw Exception('Admin user ID is missing.');
    }
    if (trimmedReason.isEmpty) {
      throw Exception('Moderation reason is required.');
    }

    final listingRef = _firestore.collection(collection).doc(trimmedListingId);
    final listingSnap = await listingRef.get();
    final data = listingSnap.data();
    if (data == null) {
      throw Exception('Listing not found.');
    }
    final ownerId = ((data[ownerField] as String?) ?? '').trim();
    final ownerName = ((data[ownerNameField] as String?) ?? '').trim();
    final title = ((data['title'] as String?) ?? '').trim();
    if (ownerId.isEmpty) {
      throw Exception('Listing owner is missing.');
    }

    final batch = _firestore.batch();
    final updates = <String, dynamic>{
      'status': archivedStatus,
      ...extraUpdates,
      'adminModerationReason': trimmedReason,
      'adminModeratedBy': trimmedAdminUid,
      'adminModeratedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (clearModerationFields) {
      updates['adminModerationReason'] = FieldValue.delete();
      updates['adminModeratedBy'] = FieldValue.delete();
      updates['adminModeratedAt'] = FieldValue.delete();
    }
    batch.update(listingRef, updates);
    batch.set(_firestore.collection(AppConstants.notificationsCollection).doc(), {
      'userId': ownerId,
      'type': AppConstants.notificationTypeAdminWarning,
      'title': notificationTitle,
      'body': '$notificationBody Reason: $trimmedReason',
      'category': 'Admin',
      'read': false,
      'actorId': trimmedAdminUid,
      'listingId': trimmedListingId,
      'listingType': listingType,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_firestore.collection(AppConstants.activityLogsCollection).doc(), {
      'type': activityType,
      'actorId': trimmedAdminUid,
      'targetUserId': ownerId,
      'targetUserName': ownerName,
      'listingId': trimmedListingId,
      'listingType': listingType,
      'listingTitle': title,
      'reason': trimmedReason,
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore security rules for admin listing moderation.',
        );
      }
      throw Exception(e.message ?? e.code);
    }
  }
}
