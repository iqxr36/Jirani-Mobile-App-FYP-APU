import 'package:flutter/foundation.dart';
import 'package:fyp_flutter_application/data/models/app_user.dart';
import 'package:fyp_flutter_application/models/service_model.dart';
import 'package:fyp_flutter_application/models/service_request_model.dart';
import 'package:fyp_flutter_application/services/service_service.dart';

class ServiceProvider extends ChangeNotifier {
  ServiceProvider({ServiceService? service}) : _service = service ?? ServiceService();

  final ServiceService _service;

  bool _busy = false;
  bool get isLoading => _busy;

  Stream<List<ServiceModel>>? _activeCache;
  final Map<String, Stream<List<ServiceModel>>> _myServicesCache = {};
  final Map<String, Stream<List<ServiceRequestModel>>> _myReqCache = {};
  final Map<String, Stream<List<ServiceRequestModel>>> _incomingCache = {};

  Stream<List<ServiceModel>> activeServicesStream() {
    _activeCache ??= _service.watchActiveServices();
    return _activeCache!;
  }

  Stream<List<ServiceModel>> myServicesStream(String providerId) {
    return _myServicesCache.putIfAbsent(providerId, () => _service.watchMyServices(providerId));
  }

  Stream<List<ServiceRequestModel>> myRequestsStream(String requesterId) {
    return _myReqCache.putIfAbsent(requesterId, () => _service.watchMyServiceRequests(requesterId));
  }

  Stream<List<ServiceRequestModel>> incomingRequestsStream(String providerId) {
    return _incomingCache.putIfAbsent(providerId, () => _service.watchIncomingServiceRequests(providerId));
  }

  Future<ServiceModel?> getService(String serviceId) => _service.getService(serviceId);

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

  Future<void> setServiceStatus({
    required String serviceId,
    required String providerId,
    required String status,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      await _service.setServiceStatus(serviceId: serviceId, providerId: providerId, status: status);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

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

  Future<void> acceptServiceRequest({required String requestId, required String providerId}) async {
    _busy = true;
    notifyListeners();
    try {
      await _service.acceptServiceRequest(requestId: requestId, providerId: providerId);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> rejectServiceRequest({required String requestId, required String providerId}) async {
    _busy = true;
    notifyListeners();
    try {
      await _service.rejectServiceRequest(requestId: requestId, providerId: providerId);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> cancelServiceRequest({required String requestId, required String requesterId}) async {
    _busy = true;
    notifyListeners();
    try {
      await _service.cancelServiceRequest(requestId: requestId, requesterId: requesterId);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> completeServiceRequest({required String requestId, required String providerId}) async {
    _busy = true;
    notifyListeners();
    try {
      await _service.completeServiceRequest(requestId: requestId, providerId: providerId);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
