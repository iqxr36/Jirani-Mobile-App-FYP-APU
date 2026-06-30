import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/service_model.dart';
import 'package:jirani/shared/models/service_request_model.dart';

/// Services feature service: manages service listings and resident service requests in Firestore.
class ServiceService {
  ServiceService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _services =>
      _firestore.collection(AppConstants.servicesCollection);

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection(AppConstants.serviceRequestsCollection);

  /// Services browse: streams all active services shown to residents.
  Stream<List<ServiceModel>> watchActiveServices() {
    return _services
        .where('status', isEqualTo: AppConstants.serviceStatusActive)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((d) => ServiceModel.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Services provider dashboard: streams services created by the current provider.
  Stream<List<ServiceModel>> watchMyServices(String providerId) {
    return _services.where('providerId', isEqualTo: providerId).snapshots().map(
      (snapshot) {
        final list = snapshot.docs
            .map((d) => ServiceModel.fromMap(d.id, d.data()))
            .toList();
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return list;
      },
    );
  }

  /// Services feature: loads one service listing by id for detail/request flows.
  Future<ServiceModel?> getService(String serviceId) async {
    final snap = await _services.doc(serviceId).get();
    final data = snap.data();
    if (data == null) return null;
    return ServiceModel.fromMap(snap.id, data);
  }

  /// Services requester dashboard: streams service requests sent by the current resident.
  Stream<List<ServiceRequestModel>> watchMyServiceRequests(String requesterId) {
    return _requests
        .where('requesterId', isEqualTo: requesterId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((d) => ServiceRequestModel.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Services provider dashboard: streams requests received by a service provider.
  Stream<List<ServiceRequestModel>> watchIncomingServiceRequests(
    String providerId,
  ) {
    return _requests.where('providerId', isEqualTo: providerId).snapshots().map(
      (snapshot) {
        final list = snapshot.docs
            .map((d) => ServiceRequestModel.fromMap(d.id, d.data()))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  /// Services provider flow: validates and creates a service listing for a verified resident.
  Future<void> createService({
    required AppUser provider,
    required String title,
    required String description,
    required String category,
    required String priceType,
    double? priceAmount,
    required String availability,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != provider.uid) {
      throw Exception('Missing user profile. Please sign in again.');
    }
    if (!provider.isVerifiedResident) {
      throw Exception('Only verified residents can list services.');
    }
    final allowedCategories = {
      AppConstants.serviceCategoryCleaning,
      AppConstants.serviceCategoryTutoring,
      AppConstants.serviceCategoryRepair,
      AppConstants.serviceCategoryDelivery,
      AppConstants.serviceCategoryPetCare,
      AppConstants.serviceCategoryOther,
    };
    if (!allowedCategories.contains(category)) {
      throw Exception('Invalid service category.');
    }
    final allowedPrice = {
      AppConstants.servicePriceTypeFree,
      AppConstants.servicePriceTypeFixed,
      AppConstants.servicePriceTypeNegotiable,
    };
    if (!allowedPrice.contains(priceType)) {
      throw Exception('Invalid price type.');
    }
    final t = title.trim();
    final d = description.trim();
    final av = availability.trim();
    if (t.isEmpty || d.isEmpty || av.isEmpty) {
      throw Exception('Title, description, and availability are required.');
    }
    double? amount = priceAmount;
    if (priceType == AppConstants.servicePriceTypeFree) {
      amount = null;
    } else if (priceType == AppConstants.servicePriceTypeFixed) {
      if (amount == null || amount < 0) {
        throw Exception('Enter a valid fixed price.');
      }
    } else {
      // negotiable — amount optional
      if (amount != null && amount < 0) {
        throw Exception('Enter a valid price amount.');
      }
    }

    try {
      final now = FieldValue.serverTimestamp();
      final doc = _services.doc();
      await doc.set({
        'id': doc.id,
        'providerId': provider.uid,
        'providerName': provider.fullName,
        'providerEmail': provider.email,
        'title': t,
        'description': d,
        'category': category,
        'priceType': priceType,
        'priceAmount': amount,
        'availability': av,
        'status': AppConstants.serviceStatusActive,
        'createdAt': now,
        'updatedAt': now,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for services.',
        );
      }
      throw Exception(e.message ?? 'Failed to create service.');
    }
  }

  /// Services provider flow: activates, deactivates, or archives a provider's own service.
  Future<void> setServiceStatus({
    required String serviceId,
    required String providerId,
    required String status,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != providerId) {
      throw Exception('Missing user profile. Please sign in again.');
    }
    final allowed = {
      AppConstants.serviceStatusActive,
      AppConstants.serviceStatusInactive,
      AppConstants.serviceStatusArchived,
    };
    if (!allowed.contains(status)) {
      throw Exception('Invalid service status.');
    }
    try {
      final ref = _services.doc(serviceId);
      final snap = await ref.get();
      final data = snap.data();
      if (data == null) throw Exception('Service not found.');
      final s = ServiceModel.fromMap(snap.id, data);
      if (s.providerId != providerId) {
        throw Exception('Only the provider can update this service.');
      }
      await ref.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for services.',
        );
      }
      throw Exception(e.message ?? 'Failed to update service.');
    }
  }

  /// Services requester flow: creates a pending request for another resident's active service.
  Future<void> createServiceRequest({
    required ServiceModel service,
    required AppUser requester,
    required String message,
    required DateTime preferredDate,
    required String preferredTime,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != requester.uid) {
      throw Exception('Missing user profile. Please sign in again.');
    }
    if (!requester.isVerifiedResident) {
      throw Exception('Only verified residents can request services.');
    }
    if (requester.uid == service.providerId) {
      throw Exception('You cannot request your own service.');
    }
    if (service.status != AppConstants.serviceStatusActive) {
      throw Exception('This service is not available.');
    }
    final msg = message.trim();
    final pt = preferredTime.trim();
    if (msg.isEmpty) {
      throw Exception('Please enter a message for the provider.');
    }
    if (pt.isEmpty) {
      throw Exception('Preferred time is required.');
    }

    try {
      final now = FieldValue.serverTimestamp();
      final doc = _requests.doc();
      await doc.set({
        'id': doc.id,
        'serviceId': service.id,
        'serviceTitle': service.title,
        'providerId': service.providerId,
        'providerName': service.providerName,
        'requesterId': requester.uid,
        'requesterName': requester.fullName,
        'message': msg,
        'preferredDate': Timestamp.fromDate(
          DateTime(preferredDate.year, preferredDate.month, preferredDate.day),
        ),
        'preferredTime': pt,
        'status': AppConstants.serviceRequestStatusPending,
        'createdAt': now,
        'updatedAt': now,
      });
      // Service request notifications are created server-side by Cloud Functions.
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for service requests.',
        );
      }
      throw Exception(e.message ?? 'Failed to submit service request.');
    }
  }

  /// Services provider flow: accepts a pending service request.
  Future<void> acceptServiceRequest({
    required String requestId,
    required String providerId,
  }) async {
    await _updateServiceRequestStatus(
      requestId: requestId,
      actingUserId: providerId,
      actorIsProvider: true,
      fromStatuses: {AppConstants.serviceRequestStatusPending},
      toStatus: AppConstants.serviceRequestStatusAccepted,
    );
  }

  /// Services provider flow: rejects a pending service request.
  Future<void> rejectServiceRequest({
    required String requestId,
    required String providerId,
  }) async {
    await _updateServiceRequestStatus(
      requestId: requestId,
      actingUserId: providerId,
      actorIsProvider: true,
      fromStatuses: {AppConstants.serviceRequestStatusPending},
      toStatus: AppConstants.serviceRequestStatusRejected,
    );
  }

  /// Services requester flow: cancels a pending service request before provider acceptance.
  Future<void> cancelServiceRequest({
    required String requestId,
    required String requesterId,
  }) async {
    await _updateServiceRequestStatus(
      requestId: requestId,
      actingUserId: requesterId,
      actorIsProvider: false,
      fromStatuses: {AppConstants.serviceRequestStatusPending},
      toStatus: AppConstants.serviceRequestStatusCancelled,
    );
  }

  /// Services provider flow: marks an accepted service request as completed.
  Future<void> completeServiceRequest({
    required String requestId,
    required String providerId,
  }) async {
    await _updateServiceRequestStatus(
      requestId: requestId,
      actingUserId: providerId,
      actorIsProvider: true,
      fromStatuses: {AppConstants.serviceRequestStatusAccepted},
      toStatus: AppConstants.serviceRequestStatusCompleted,
    );
  }

  /// Services request lifecycle: validates actor ownership and transitions request status.
  Future<void> _updateServiceRequestStatus({
    required String requestId,
    required String actingUserId,
    required bool actorIsProvider,
    required Set<String> fromStatuses,
    required String toStatus,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != actingUserId) {
      throw Exception('Missing user profile. Please sign in again.');
    }
    try {
      final ref = _requests.doc(requestId);
      final snap = await ref.get();
      final data = snap.data();
      if (data == null) throw Exception('Service request not found.');
      final r = ServiceRequestModel.fromMap(snap.id, data);
      if (!fromStatuses.contains(r.status)) {
        throw Exception('Invalid service request status for this action.');
      }
      if (actorIsProvider && r.providerId != actingUserId) {
        throw Exception('Only the provider can perform this action.');
      }
      if (!actorIsProvider && r.requesterId != actingUserId) {
        throw Exception('Only the requester can perform this action.');
      }
      await ref.update({
        'status': toStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Service status notifications are created server-side by Cloud Functions.
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for service requests.',
        );
      }
      throw Exception(e.message ?? 'Failed to update service request.');
    }
  }
}
