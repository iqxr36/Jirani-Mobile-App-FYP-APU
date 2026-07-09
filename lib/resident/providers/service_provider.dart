import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/service_model.dart';
import 'package:jirani/shared/models/service_request_model.dart';
import 'package:jirani/shared/services/service_service.dart';

// Services feature: manages service listings and service requests for resident provider/requester screens.
class ServiceProvider extends ChangeNotifier {
  ServiceProvider({ServiceService? service})
    : _service = service ?? ServiceService();

  final ServiceService _service;

  bool _busy = false;
  bool get isLoading => _busy;

  // Services feature: streams active community services and caches the stream for list screens.
  Stream<List<ServiceModel>> activeServicesStream({required String communityId}) {
    return _service.watchActiveServices(communityId: communityId.trim());
  }

  // Services feature: streams services created by the current provider.
  Stream<List<ServiceModel>> myServicesStream(String providerId) {
    return _service.watchMyServices(providerId);
  }

  // Services feature: streams requests the current resident has sent to service providers.
  Stream<List<ServiceRequestModel>> myRequestsStream(String requesterId) {
    return _service.watchMyServiceRequests(requesterId);
  }

  // Services feature: streams requests received by the current service provider.
  Stream<List<ServiceRequestModel>> incomingRequestsStream(String providerId) {
    return _service.watchIncomingServiceRequests(providerId);
  }

  // Services transaction tracking: streams one request for a live detail screen.
  Stream<ServiceRequestModel?> requestStream(String requestId) {
    return _service.watchServiceRequest(requestId);
  }

  // Services feature: loads a single service for detail or notification navigation.
  Future<ServiceModel?> getService(String serviceId) =>
      _service.getService(serviceId);

  // Services notification deep links: loads one request for transaction navigation.
  Future<ServiceRequestModel?> fetchServiceRequest(String requestId) =>
      _service.fetchServiceRequest(requestId);

  // Services feature: creates a provider service listing; service payments are intentionally not active yet.
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
    _busy = true;
    notifyListeners();
    try {
      await _service.createService(
        provider: provider,
        title: title,
        description: description,
        category: category,
        priceType: priceType,
        priceAmount: priceAmount,
        pricingMode: pricingMode,
        hourlyRate: hourlyRate,
        fixedJobPrice: fixedJobPrice,
        availability: availability,
        availableWeekdays: availableWeekdays,
        availabilityStartTime: availabilityStartTime,
        availabilityEndTime: availabilityEndTime,
        imagePaths: imagePaths,
        certificatePaths: certificatePaths,
        certificateNames: certificateNames,
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // Services feature: updates provider-owned editable service listing fields.
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
    _busy = true;
    notifyListeners();
    try {
      await _service.updateService(
        provider: provider,
        service: service,
        title: title,
        description: description,
        category: category,
        priceType: priceType,
        priceAmount: priceAmount,
        pricingMode: pricingMode,
        hourlyRate: hourlyRate,
        fixedJobPrice: fixedJobPrice,
        availability: availability,
        availableWeekdays: availableWeekdays,
        availabilityStartTime: availabilityStartTime,
        availabilityEndTime: availabilityEndTime,
        imagePaths: imagePaths,
        certificatePaths: certificatePaths,
        certificateNames: certificateNames,
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> repairMissingServiceCommunityIds({
    required AppUser provider,
    required Iterable<String> serviceIds,
  }) async {
    await _service.repairMissingServiceCommunityIds(
      provider: provider,
      serviceIds: serviceIds,
    );
  }

  // Services feature: lets a provider activate/archive their service listing.
  Future<void> setServiceStatus({
    required String serviceId,
    required String providerId,
    required String status,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      await _service.setServiceStatus(
        serviceId: serviceId,
        providerId: providerId,
        status: status,
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // Services feature: creates a request from a resident to a service provider.
  Future<void> createServiceRequest({
    required ServiceModel service,
    required AppUser requester,
    required String message,
    required DateTime preferredDate,
    required String preferredTime,
    int? durationHours,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      await _service.createServiceRequest(
        service: service,
        requester: requester,
        message: message,
        preferredDate: preferredDate,
        preferredTime: preferredTime,
        durationHours: durationHours,
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // Services feature: provider accepts a service request.
  Future<void> acceptServiceRequest({
    required String requestId,
    required String providerId,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      await _service.acceptServiceRequest(
        requestId: requestId,
        providerId: providerId,
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // Services feature: provider rejects a service request.
  Future<void> rejectServiceRequest({
    required String requestId,
    required String providerId,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      await _service.rejectServiceRequest(
        requestId: requestId,
        providerId: providerId,
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // Services feature: requester cancels their own pending service request.
  Future<void> cancelServiceRequest({
    required String requestId,
    required String requesterId,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      await _service.cancelServiceRequest(
        requestId: requestId,
        requesterId: requesterId,
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // Services feature: provider marks an accepted service request as completed.
  Future<void> completeServiceRequest({
    required String requestId,
    required String providerId,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      await _service.completeServiceRequest(
        requestId: requestId,
        providerId: providerId,
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> generateArrivalCode({
    required String requestId,
    required String providerId,
  }) async {
    return _runWithResult(
      () => _service.generateArrivalCode(
        requestId: requestId,
        providerId: providerId,
      ),
    );
  }

  Future<void> submitArrivalCode({
    required String requestId,
    required String requesterId,
    required String code,
  }) async {
    await _runVoid(
      () => _service.submitArrivalCode(
        requestId: requestId,
        requesterId: requesterId,
        code: code,
      ),
    );
  }

  Future<String?> generateCompletionCode({
    required String requestId,
    required String requesterId,
  }) async {
    return _runWithResult(
      () => _service.generateCompletionCode(
        requestId: requestId,
        requesterId: requesterId,
      ),
    );
  }

  Future<void> submitCompletionCode({
    required String requestId,
    required String providerId,
    required String code,
  }) async {
    await _runVoid(
      () => _service.submitCompletionCode(
        requestId: requestId,
        providerId: providerId,
        code: code,
      ),
    );
  }

  Future<void> disputeServiceRequest({
    required String requestId,
    required String requesterId,
    required String disputeType,
    required String details,
  }) async {
    await _runVoid(
      () => _service.disputeServiceRequest(
        requestId: requestId,
        requesterId: requesterId,
        disputeType: disputeType,
        details: details,
      ),
    );
  }

  Future<T?> _runWithResult<T>(Future<T> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _runVoid(Future<void> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
