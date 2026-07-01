import 'package:flutter/foundation.dart';
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

  Stream<List<ServiceModel>>? _activeCache;
  final Map<String, Stream<List<ServiceModel>>> _myServicesCache = {};
  final Map<String, Stream<List<ServiceRequestModel>>> _myReqCache = {};
  final Map<String, Stream<List<ServiceRequestModel>>> _incomingCache = {};

  // Services feature: streams active community services and caches the stream for list screens.
  Stream<List<ServiceModel>> activeServicesStream() {
    _activeCache ??= _service.watchActiveServices();
    return _activeCache!;
  }

  // Services feature: streams services created by the current provider.
  Stream<List<ServiceModel>> myServicesStream(String providerId) {
    return _myServicesCache.putIfAbsent(
      providerId,
      () => _service.watchMyServices(providerId),
    );
  }

  // Services feature: streams requests the current resident has sent to service providers.
  Stream<List<ServiceRequestModel>> myRequestsStream(String requesterId) {
    return _myReqCache.putIfAbsent(
      requesterId,
      () => _service.watchMyServiceRequests(requesterId),
    );
  }

  // Services feature: streams requests received by the current service provider.
  Stream<List<ServiceRequestModel>> incomingRequestsStream(String providerId) {
    return _incomingCache.putIfAbsent(
      providerId,
      () => _service.watchIncomingServiceRequests(providerId),
    );
  }

  // Services feature: loads a single service for detail or notification navigation.
  Future<ServiceModel?> getService(String serviceId) =>
      _service.getService(serviceId);

  // Services feature: creates a provider service listing; service payments are intentionally not active yet.
  Future<void> createService({
    required AppUser provider,
    required String title,
    required String description,
    required String category,
    required String priceType,
    double? priceAmount,
    required String availability,
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
        availability: availability,
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
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
}
