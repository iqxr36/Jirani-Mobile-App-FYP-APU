import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fyp_flutter_application/data/models/verification_request.dart';
import 'package:fyp_flutter_application/services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider({AdminService? service}) : _service = service ?? AdminService();

  final AdminService _service;

  bool _isLoading = false;
  String? _errorMessage;
  List<VerificationRequest> _verificationRequests = const <VerificationRequest>[];
  VerificationRequest? _selectedRequest;
  String _selectedStatusFilter = 'submitted';
  Map<String, int> _dashboardStats = const <String, int>{};
  StreamSubscription<List<VerificationRequest>>? _requestsSub;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<VerificationRequest> get verificationRequests => _verificationRequests;
  VerificationRequest? get selectedRequest => _selectedRequest;
  String get selectedStatusFilter => _selectedStatusFilter;
  Map<String, int> get dashboardStats => _dashboardStats;

  void watchVerificationRequests({String status = 'submitted'}) {
    _selectedStatusFilter = status;
    _requestsSub?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _requestsSub = _service.watchVerificationRequests(status: status).listen(
      (requests) {
        _verificationRequests = requests;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> loadVerificationRequestById(String requestId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _selectedRequest = await _service.getVerificationRequestById(requestId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveRequest({
    required VerificationRequest request,
    required String adminUid,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.approveVerificationRequest(
        requestId: request.id,
        residentUid: request.userId,
        adminUid: adminUid,
      );
      await loadVerificationRequestById(request.id);
      await loadDashboardStats();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectRequest({
    required VerificationRequest request,
    required String adminUid,
    required String rejectionReason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.rejectVerificationRequest(
        requestId: request.id,
        residentUid: request.userId,
        adminUid: adminUid,
        rejectionReason: rejectionReason,
      );
      await loadVerificationRequestById(request.id);
      await loadDashboardStats();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboardStats() async {
    try {
      _dashboardStats = await _service.getAdminDashboardStats();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    watchVerificationRequests(status: status);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _requestsSub?.cancel();
    super.dispose();
  }
}
