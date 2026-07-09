import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/service_model.dart';
import 'package:jirani/shared/models/service_request_model.dart';
import 'package:jirani/shared/utils/service_availability.dart';
import 'package:mime/mime.dart';

/// Services feature service: manages service listings and resident service requests in Firestore.
class ServiceService {
  ServiceService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _services =>
      _firestore.collection(AppConstants.servicesCollection);

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection(AppConstants.serviceRequestsCollection);

  /// Services browse: streams all active services shown to residents.
  Stream<List<ServiceModel>> watchActiveServices({required String communityId}) {
    final scopedCommunityId = communityId.trim();
    if (scopedCommunityId.isEmpty) {
      return Stream<List<ServiceModel>>.value(const <ServiceModel>[]);
    }
    final query = _services.where(
      'status',
      isEqualTo: AppConstants.serviceStatusActive,
    ).where('communityId', isEqualTo: scopedCommunityId);
    return query.snapshots().map((snapshot) {
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

  /// Services transaction tracking: streams one service request by id.
  Stream<ServiceRequestModel?> watchServiceRequest(String requestId) {
    return _requests.doc(requestId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return ServiceRequestModel.fromMap(snapshot.id, data);
    });
  }

  /// Services notification deep links: loads one request for navigation.
  Future<ServiceRequestModel?> fetchServiceRequest(String requestId) async {
    final snap = await _requests.doc(requestId).get();
    final data = snap.data();
    if (data == null) return null;
    return ServiceRequestModel.fromMap(snap.id, data);
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

  /// Services provider flow: validates and creates a rich service listing.
  Future<void> createService({
    required AppUser provider,
    required String title,
    required String description,
    required String category,
    required String priceType,
    double? priceAmount,
    required String pricingMode,
    double? hourlyRate,
    double? fixedJobPrice,
    required String availability,
    required Set<int> availableWeekdays,
    required TimeOfDay availabilityStartTime,
    required TimeOfDay availabilityEndTime,
    List<String> imagePaths = const <String>[],
    List<String> certificatePaths = const <String>[],
    List<String> certificateNames = const <String>[],
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != provider.uid) {
      throw Exception('Missing user profile. Please sign in again.');
    }
    if (!provider.isVerifiedResident) {
      throw Exception('Only verified residents can list services.');
    }
    final allowedCategories = {
      AppConstants.serviceCategoryHomeCleaningUpkeep,
      AppConstants.serviceCategoryRepairsMaintenance,
      AppConstants.serviceCategoryAssemblyLabor,
      AppConstants.serviceCategoryTutoringEducation,
      AppConstants.serviceCategoryAssistanceErrands,
      AppConstants.serviceCategoryItTechSetup,
      AppConstants.serviceCategoryHomeCookingMealPrep,
      AppConstants.serviceCategoryCreativeDigitalTasks,
    };
    if (!allowedCategories.contains(category)) {
      throw Exception('Invalid service category.');
    }
    final allowedPricingModes = {
      AppConstants.servicePricingModeHourly,
      AppConstants.servicePricingModeFixedJob,
    };
    if (!allowedPricingModes.contains(pricingMode)) {
      throw Exception('Invalid service pricing mode.');
    }
    final t = title.trim();
    final d = description.trim();
    final av = availability.trim();
    if (t.isEmpty || d.isEmpty || av.isEmpty) {
      throw Exception('Title, description, and availability are required.');
    }
    final availabilityFields = availabilityFieldsForServiceWrite(
      weekdays: availableWeekdays,
      startTime: availabilityStartTime,
      endTime: availabilityEndTime,
    );
    _validateServiceImages(imagePaths);
    _validateServiceCertificates(certificatePaths);
    if (certificateNames.length != certificatePaths.length) {
      throw Exception('Certificate file names do not match selected files.');
    }

    double? resolvedHourlyRate;
    double? resolvedFixedJobPrice;
    double resolvedPriceAmount;
    if (pricingMode == AppConstants.servicePricingModeHourly) {
      if (hourlyRate == null || hourlyRate <= 0) {
        throw Exception('Enter a valid hourly rate.');
      }
      if (!provider.hasVerifiedPayoutAccount) {
        throw Exception(
          'Add and verify your payout account before listing paid services.',
        );
      }
      resolvedHourlyRate = hourlyRate;
      resolvedPriceAmount = hourlyRate;
    } else {
      if (fixedJobPrice == null || fixedJobPrice <= 0) {
        throw Exception('Enter a valid fixed job price.');
      }
      if (!provider.hasVerifiedPayoutAccount) {
        throw Exception(
          'Add and verify your payout account before listing paid services.',
        );
      }
      resolvedFixedJobPrice = fixedJobPrice;
      resolvedPriceAmount = fixedJobPrice;
    }

    final uploadedRefs = <Reference>[];
    try {
      final now = FieldValue.serverTimestamp();
      final doc = _services.doc();
      final imageUpload = await _uploadServiceFiles(
        uid: uid,
        serviceId: doc.id,
        folder: 'job_photos',
        filePaths: imagePaths,
        allowPdf: false,
      );
      uploadedRefs.addAll(imageUpload.refs);
      final certificateUpload = await _uploadServiceFiles(
        uid: uid,
        serviceId: doc.id,
        folder: 'certificates',
        filePaths: certificatePaths,
        allowPdf: true,
      );
      uploadedRefs.addAll(certificateUpload.refs);

      await doc.set({
        'id': doc.id,
        'providerId': provider.uid,
        'providerName': provider.fullName,
        'providerEmail': provider.email,
        'communityId': provider.communityId,
        'communityName': provider.communityName,
        'providerPhotoUrl': provider.profileImageUrl,
        'title': t,
        'description': d,
        'category': category,
        'priceType': AppConstants.servicePriceTypeFixed,
        'priceAmount': resolvedPriceAmount,
        'pricingMode': pricingMode,
        'hourlyRate': resolvedHourlyRate,
        'fixedJobPrice': resolvedFixedJobPrice,
        'imageUrls': imageUpload.urls,
        'certificateUrls': certificateUpload.urls,
        'certificateNames': certificateNames.map((name) => name.trim()).toList(),
        'availability': av,
        ...availabilityFields,
        'status': AppConstants.serviceStatusActive,
        'createdAt': now,
        'updatedAt': now,
      });
    } on FirebaseException catch (e) {
      await _deleteUploadedFiles(uploadedRefs);
      if (e.code == 'permission-denied') {
        throw Exception(
          'Storage upload was denied. Deploy Storage rules or choose a supported file type.',
        );
      }
      throw Exception(e.message ?? 'Failed to create service.');
    } catch (_) {
      await _deleteUploadedFiles(uploadedRefs);
      rethrow;
    }
  }

  /// Services provider repair: backfills visibility fields on old provider-owned listings.
  Future<void> repairMissingServiceCommunityIds({
    required AppUser provider,
    required Iterable<String> serviceIds,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != provider.uid) return;
    final ids = serviceIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (ids.isEmpty) return;
    await _call('repairOwnServiceCommunityIds', {'serviceIds': ids});
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

  /// Services provider flow: updates editable fields on an active provider-owned service.
  Future<void> updateService({
    required AppUser provider,
    required ServiceModel service,
    required String title,
    required String description,
    required String category,
    required String priceType,
    double? priceAmount,
    required String pricingMode,
    double? hourlyRate,
    double? fixedJobPrice,
    required String availability,
    required Set<int> availableWeekdays,
    required TimeOfDay availabilityStartTime,
    required TimeOfDay availabilityEndTime,
    List<String> imagePaths = const <String>[],
    List<String> certificatePaths = const <String>[],
    List<String> certificateNames = const <String>[],
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != provider.uid) {
      throw Exception('Missing user profile. Please sign in again.');
    }
    if (service.providerId != provider.uid) {
      throw Exception('Only the provider can edit this service.');
    }
    if (service.status != AppConstants.serviceStatusActive) {
      throw Exception('Archived services must be unarchived before editing.');
    }
    if (!provider.isVerifiedResident) {
      throw Exception('Only verified residents can edit services.');
    }

    final allowedCategories = {
      AppConstants.serviceCategoryHomeCleaningUpkeep,
      AppConstants.serviceCategoryRepairsMaintenance,
      AppConstants.serviceCategoryAssemblyLabor,
      AppConstants.serviceCategoryTutoringEducation,
      AppConstants.serviceCategoryAssistanceErrands,
      AppConstants.serviceCategoryItTechSetup,
      AppConstants.serviceCategoryHomeCookingMealPrep,
      AppConstants.serviceCategoryCreativeDigitalTasks,
    };
    if (!allowedCategories.contains(category)) {
      throw Exception('Invalid service category.');
    }
    final allowedPricingModes = {
      AppConstants.servicePricingModeHourly,
      AppConstants.servicePricingModeFixedJob,
    };
    if (!allowedPricingModes.contains(pricingMode)) {
      throw Exception('Invalid service pricing mode.');
    }

    final t = title.trim();
    final d = description.trim();
    final av = availability.trim();
    if (t.isEmpty || d.isEmpty || av.isEmpty) {
      throw Exception('Title, description, and availability are required.');
    }
    final availabilityFields = availabilityFieldsForServiceWrite(
      weekdays: availableWeekdays,
      startTime: availabilityStartTime,
      endTime: availabilityEndTime,
    );
    _validateServiceImages(imagePaths);
    _validateServiceCertificates(certificatePaths);
    if (certificateNames.length != certificatePaths.length) {
      throw Exception('Certificate file names do not match selected files.');
    }

    double? resolvedHourlyRate;
    double? resolvedFixedJobPrice;
    double resolvedPriceAmount;
    if (pricingMode == AppConstants.servicePricingModeHourly) {
      if (hourlyRate == null || hourlyRate <= 0) {
        throw Exception('Enter a valid hourly rate.');
      }
      if (!provider.hasVerifiedPayoutAccount) {
        throw Exception(
          'Add and verify your payout account before listing paid services.',
        );
      }
      resolvedHourlyRate = hourlyRate;
      resolvedPriceAmount = hourlyRate;
    } else {
      if (fixedJobPrice == null || fixedJobPrice <= 0) {
        throw Exception('Enter a valid fixed job price.');
      }
      if (!provider.hasVerifiedPayoutAccount) {
        throw Exception(
          'Add and verify your payout account before listing paid services.',
        );
      }
      resolvedFixedJobPrice = fixedJobPrice;
      resolvedPriceAmount = fixedJobPrice;
    }

    final uploadedRefs = <Reference>[];
    try {
      final imageUpload = await _uploadServiceFiles(
        uid: uid,
        serviceId: service.id,
        folder: 'job_photos',
        filePaths: imagePaths,
        allowPdf: false,
      );
      uploadedRefs.addAll(imageUpload.refs);
      final certificateUpload = await _uploadServiceFiles(
        uid: uid,
        serviceId: service.id,
        folder: 'certificates',
        filePaths: certificatePaths,
        allowPdf: true,
      );
      uploadedRefs.addAll(certificateUpload.refs);

      await _services.doc(service.id).update({
        'title': t,
        'description': d,
        'category': category,
        'communityId': provider.communityId,
        'communityName': provider.communityName,
        'priceType': AppConstants.servicePriceTypeFixed,
        'priceAmount': resolvedPriceAmount,
        'pricingMode': pricingMode,
        'hourlyRate': resolvedHourlyRate,
        'fixedJobPrice': resolvedFixedJobPrice,
        'imageUrls': [...service.imageUrls, ...imageUpload.urls],
        'certificateUrls': [
          ...service.certificateUrls,
          ...certificateUpload.urls,
        ],
        'certificateNames': [
          ...service.certificateNames,
          ...certificateNames.map((name) => name.trim()),
        ],
        'availability': av,
        ...availabilityFields,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      await _deleteUploadedFiles(uploadedRefs);
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Check Firestore rules for services.',
        );
      }
      throw Exception(e.message ?? 'Failed to update service.');
    } catch (_) {
      await _deleteUploadedFiles(uploadedRefs);
      rethrow;
    }
  }

  /// Services requester flow: creates a pending request for another resident's active service.
  Future<void> createServiceRequest({
    required ServiceModel service,
    required AppUser requester,
    required String message,
    required DateTime preferredDate,
    required String preferredTime,
    int? durationHours,
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

    final schedule = parseServiceAvailability(service);
    validateServiceAvailability(
      schedule: schedule,
      preferredDate: preferredDate,
      preferredTimeLabel: pt,
    );
    final preferredWeekday = weekdayFromDate(preferredDate);
    final preferredTimeMinutes = minutesFromPreferredTimeLabel(pt);
    if (preferredTimeMinutes == null) {
      throw Exception('Choose a valid preferred time.');
    }

    try {
      final now = FieldValue.serverTimestamp();
      final doc = _requests.doc();
      final isHourlyService =
          service.pricingMode == AppConstants.servicePricingModeHourly;
      final isFixedJobService =
          service.pricingMode == AppConstants.servicePricingModeFixedJob ||
          (service.pricingMode.isEmpty &&
              service.priceType == AppConstants.servicePriceTypeFixed);
      int? resolvedDurationHours;
      double? resolvedHourlyRate;
      double? requestAmount;
      if (isHourlyService) {
        final hours = durationHours ?? 0;
        final rate = service.hourlyRate ?? service.priceAmount ?? 0;
        if (hours <= 0) {
          throw Exception('Select how many hours you need.');
        }
        if (rate <= 0) {
          throw Exception('This hourly service is missing its rate.');
        }
        resolvedDurationHours = hours;
        resolvedHourlyRate = rate;
        requestAmount = rate * hours;
      } else if (isFixedJobService) {
        requestAmount = service.fixedJobPrice ?? service.priceAmount;
      }
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
        'preferredWeekday': preferredWeekday,
        'preferredTimeMinutes': preferredTimeMinutes,
        'amount': requestAmount,
        'durationHours': resolvedDurationHours,
        'hourlyRate': resolvedHourlyRate,
        'currency': AppConstants.defaultPaymentCurrency,
        'paymentStatus': AppConstants.paymentStatusPending,
        'paymentId': '',
        'paymentProvider': '',
        'platformFeeAmount': 0,
        'providerPayoutAmount': requestAmount ?? 0,
        'payoutStatus': AppConstants.servicePayoutStatusNotStarted,
        'refundStatus': AppConstants.refundStatusNotStarted,
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
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != providerId) {
      throw Exception('Missing user profile. Please sign in again.');
    }
    final ref = _requests.doc(requestId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw Exception('Service request not found.');
    final r = ServiceRequestModel.fromMap(snap.id, data);
    if (r.providerId != providerId) {
      throw Exception('Only the provider can accept this request.');
    }
    if (r.status != AppConstants.serviceRequestStatusPending) {
      throw Exception('Invalid service request status for this action.');
    }
    final paid = (r.amount ?? 0) > 0;
    await ref.update({
      'status': paid
          ? AppConstants.serviceRequestStatusAcceptedAwaitingPayment
          : AppConstants.serviceRequestStatusAccepted,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

  /// Services requester flow: cancels a pending or awaiting-payment service request.
  Future<void> cancelServiceRequest({
    required String requestId,
    required String requesterId,
  }) async {
    await _updateServiceRequestStatus(
      requestId: requestId,
      actingUserId: requesterId,
      actorIsProvider: false,
      fromStatuses: {
        AppConstants.serviceRequestStatusPending,
        AppConstants.serviceRequestStatusAcceptedAwaitingPayment,
      },
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

  Future<String> generateArrivalCode({
    required String requestId,
    required String providerId,
  }) async {
    return _callForCode('generateServiceArrivalCode', {
      'requestId': requestId,
      'providerId': providerId,
    });
  }

  Future<void> submitArrivalCode({
    required String requestId,
    required String requesterId,
    required String code,
  }) async {
    await _call('submitServiceArrivalCode', {
      'requestId': requestId,
      'requesterId': requesterId,
      'code': code,
    });
  }

  Future<String> generateCompletionCode({
    required String requestId,
    required String requesterId,
  }) async {
    return _callForCode('generateServiceCompletionCode', {
      'requestId': requestId,
      'requesterId': requesterId,
    });
  }

  Future<void> submitCompletionCode({
    required String requestId,
    required String providerId,
    required String code,
  }) async {
    await _call('submitServiceCompletionCode', {
      'requestId': requestId,
      'providerId': providerId,
      'code': code,
    });
  }

  Future<void> disputeServiceRequest({
    required String requestId,
    required String requesterId,
    required String disputeType,
    required String details,
  }) async {
    await _call('disputeServiceRequest', {
      'requestId': requestId,
      'requesterId': requesterId,
      'disputeType': disputeType,
      'details': details,
    });
  }

  Future<void> forceServicePayout({
    required String requestId,
    required String reason,
  }) async {
    await _call('forceServicePayout', {
      'requestId': requestId,
      'reason': reason,
    });
  }

  Future<void> refundServicePayment({
    required String requestId,
    required String reason,
  }) async {
    await _call('refundServicePayment', {
      'requestId': requestId,
      'reason': reason,
    });
  }

  Future<void> _call(String name, Map<String, dynamic> data) async {
    try {
      await _functions.httpsCallable(name).call(data);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Service action failed.');
    }
  }

  Future<String> _callForCode(String name, Map<String, dynamic> data) async {
    try {
      final result = await _functions.httpsCallable(name).call(data);
      final raw = result.data;
      if (raw is Map && raw['code'] is String) return raw['code'] as String;
      return '';
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Service code action failed.');
    }
  }

  void _validateServiceImages(List<String> paths) {
    if (paths.length > 6) {
      throw Exception('Add up to 6 job photos.');
    }
    for (final path in paths) {
      final type = _serviceFileContentType(path, allowPdf: false);
      if (!type.startsWith('image/')) {
        throw Exception('Job photos must be image files.');
      }
    }
  }

  void _validateServiceCertificates(List<String> paths) {
    if (paths.length > 5) {
      throw Exception('Add up to 5 certificate files.');
    }
    for (final path in paths) {
      _serviceFileContentType(path, allowPdf: true);
    }
  }

  Future<_ServiceFileUploadResult> _uploadServiceFiles({
    required String uid,
    required String serviceId,
    required String folder,
    required List<String> filePaths,
    required bool allowPdf,
  }) async {
    final urls = <String>[];
    final refs = <Reference>[];
    for (var i = 0; i < filePaths.length; i += 1) {
      final file = File(filePaths[i]);
      if (!file.existsSync()) {
        throw Exception('Selected file is no longer available.');
      }
      final contentType = _serviceFileContentType(file.path, allowPdf: allowPdf);
      final fileName = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : 'file_$i';
      final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final ref = _storage.ref().child(
        '${AppConstants.storageServiceMediaPath}/$uid/$serviceId/$folder/${DateTime.now().microsecondsSinceEpoch}_$safeName',
      );
      await ref.putFile(file, SettableMetadata(contentType: contentType));
      refs.add(ref);
      urls.add(await ref.getDownloadURL());
    }
    return _ServiceFileUploadResult(urls: urls, refs: refs);
  }

  Future<void> _deleteUploadedFiles(List<Reference> refs) async {
    for (final ref in refs) {
      try {
        await ref.delete();
      } catch (_) {
        // Best-effort cleanup after failed listing creation.
      }
    }
  }

  String _serviceFileContentType(String fileName, {required bool allowPdf}) {
    final type = lookupMimeType(fileName) ?? '';
    final allowedImages = {
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/heic',
      'image/heif',
    };
    if (allowedImages.contains(type)) return type;
    if (allowPdf && type == 'application/pdf') return type;
    throw Exception(
      allowPdf
          ? 'Certificates must be images or PDF files.'
          : 'Job photos must be JPEG, PNG, WebP, HEIC, or HEIF images.',
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

class _ServiceFileUploadResult {
  const _ServiceFileUploadResult({required this.urls, required this.refs});

  final List<String> urls;
  final List<Reference> refs;
}
