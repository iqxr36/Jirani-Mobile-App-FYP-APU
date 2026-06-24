import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/admin_user.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/models/verification_request.dart';
import 'package:jirani/shared/models/extracted_document_data.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/report_model.dart';
import 'package:jirani/shared/models/service_request_model.dart';
import 'package:jirani/shared/models/service_model.dart';
import 'package:jirani/admin/services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider({AdminService? service}) : _service = service ?? AdminService();

  final AdminService _service;

  bool _isLoading = false;
  String? _errorMessage;
  List<VerificationRequest> _verificationRequests =
      const <VerificationRequest>[];
  List<AppUser> _residents = const <AppUser>[];
  List<ItemModel> _listings = const <ItemModel>[];
  List<ServiceModel> _services = const <ServiceModel>[];
  List<ReportModel> _reports = const <ReportModel>[];
  List<BorrowRequest> _borrowRequests = const <BorrowRequest>[];
  List<ServiceRequestModel> _serviceRequests = const <ServiceRequestModel>[];
  VerificationRequest? _selectedRequest;
  String _selectedStatusFilter = 'submitted';
  Map<String, int> _dashboardStats = const <String, int>{};
  StreamSubscription<List<VerificationRequest>>? _requestsSub;
  StreamSubscription<List<AppUser>>? _residentsSub;
  StreamSubscription<List<ItemModel>>? _listingsSub;
  StreamSubscription<List<ServiceModel>>? _servicesSub;
  StreamSubscription<List<ReportModel>>? _reportsSub;
  StreamSubscription<List<BorrowRequest>>? _borrowRequestsSub;
  StreamSubscription<List<ServiceRequestModel>>? _serviceRequestsSub;
  String _communityId = '';
  String _communityName = '';
  bool _includeAllCommunities = false;
  bool _isConfigured = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<VerificationRequest> get verificationRequests => _verificationRequests;
  List<AppUser> get residents => _residents;
  List<ItemModel> get listings => _listings;
  List<ServiceModel> get services => _visibleServices;
  List<ReportModel> get reports => _visibleReports;
  List<BorrowRequest> get borrowRequests => _visibleBorrowRequests;
  List<ServiceRequestModel> get serviceRequests => _visibleServiceRequests;
  VerificationRequest? get selectedRequest => _selectedRequest;
  String get selectedStatusFilter => _selectedStatusFilter;
  Map<String, int> get dashboardStats => _dashboardStats;
  String get communityId => _communityId;
  String get communityName => _communityName;
  bool get includeAllCommunities => _includeAllCommunities;
  bool get isConfigured => _isConfigured;
  String? get currentAdminUid => _service.currentAdminUid;

  void configureForAdmin(AdminUser admin) {
    final nextIncludeAll = admin.role == AppConstants.roleSystemAdmin;
    final nextCommunityId = admin.communityId.trim();
    final nextCommunityName = admin.communityName.trim();
    if (_isConfigured &&
        _includeAllCommunities == nextIncludeAll &&
        _communityId == nextCommunityId &&
        _communityName == nextCommunityName) {
      return;
    }

    _isConfigured = true;
    _includeAllCommunities = nextIncludeAll;
    _communityId = nextCommunityId;
    _communityName = nextCommunityName;
    watchVerificationRequests(status: _selectedStatusFilter);
    watchAdminCollections();
    loadDashboardStats();
  }

  void watchVerificationRequests({String status = 'submitted'}) {
    _selectedStatusFilter = status;
    _requestsSub?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _requestsSub = _service
        .watchVerificationRequests(
          status: status,
          communityId: _communityId,
          communityName: _communityName,
          includeAllCommunities: _includeAllCommunities,
        )
        .listen(
          (requests) {
            _verificationRequests = requests;
            _isLoading = false;
            _refreshLocalDashboardStats();
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

  void watchAdminCollections() {
    _residentsSub?.cancel();
    _listingsSub?.cancel();
    _servicesSub?.cancel();
    _reportsSub?.cancel();
    _borrowRequestsSub?.cancel();
    _serviceRequestsSub?.cancel();

    _residentsSub = _service
        .watchResidents(
          communityId: _communityId,
          communityName: _communityName,
          includeAllCommunities: _includeAllCommunities,
        )
        .listen((residents) {
          _residents = residents;
          _refreshLocalDashboardStats();
        }, onError: _handleStreamError);

    _listingsSub = _service
        .watchListings(
          communityId: _communityId,
          communityName: _communityName,
          includeAllCommunities: _includeAllCommunities,
        )
        .listen((listings) {
          _listings = listings;
          _refreshLocalDashboardStats();
        }, onError: _handleStreamError);

    _servicesSub = _service.watchServices().listen((services) {
      _services = services;
      _refreshLocalDashboardStats();
    }, onError: _handleStreamError);

    _reportsSub = _service
        .watchReports(
          communityId: _communityId,
          includeAllCommunities: _includeAllCommunities,
        )
        .listen((reports) {
          _reports = reports;
          _refreshLocalDashboardStats();
        }, onError: _handleStreamError);

    _borrowRequestsSub = _service.watchBorrowRequests().listen((requests) {
      _borrowRequests = requests;
      notifyListeners();
    }, onError: _handleStreamError);

    _serviceRequestsSub = _service.watchServiceRequests().listen((requests) {
      _serviceRequests = requests;
      notifyListeners();
    }, onError: _handleStreamError);
  }

  Future<void> approveRequest({
    required VerificationRequest request,
    required String adminUid,
    ExtractedDocumentData? reviewedOcrData,
  }) async {
    if (!_requestIsInAdminScope(request)) {
      _errorMessage = 'This request is outside your assigned community.';
      notifyListeners();
      return;
    }
    debugPrint(
      '[AdminProvider][approveRequest] started requestId=${request.id} residentUid=${request.userId} adminUid=$adminUid',
    );
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.approveVerificationRequest(
        requestId: request.id,
        residentUid: request.userId,
        adminUid: adminUid,
        reviewedOcrData: reviewedOcrData,
      );
      debugPrint('[AdminProvider][approveRequest] service call completed');
      await loadVerificationRequestById(request.id);
      await loadDashboardStats();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[AdminProvider][approveRequest] FAILED: $_errorMessage');
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
    if (!_requestIsInAdminScope(request)) {
      _errorMessage = 'This request is outside your assigned community.';
      notifyListeners();
      return;
    }
    debugPrint(
      '[AdminProvider][rejectRequest] started requestId=${request.id} residentUid=${request.userId} adminUid=$adminUid reason="$rejectionReason"',
    );
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
      debugPrint('[AdminProvider][rejectRequest] service call completed');
      await loadVerificationRequestById(request.id);
      await loadDashboardStats();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[AdminProvider][rejectRequest] FAILED: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resolveMarketplaceDispute({
    required ReportModel report,
    required BorrowRequest borrowRequest,
    required String adminUid,
    required bool resolveForBorrower,
    required String reason,
  }) async {
    if (!_belongsToVisibleResident(
      borrowRequest.ownerId,
      borrowRequest.borrowerId,
    )) {
      _errorMessage = 'This dispute is outside your assigned community.';
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.resolveMarketplaceDispute(
        reportId: report.id,
        borrowRequestId: borrowRequest.id,
        adminUid: adminUid,
        resolveForBorrower: resolveForBorrower,
        reason: reason,
      );
      await loadDashboardStats();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> dismissReport({
    required ReportModel report,
    required String adminUid,
    required String reason,
  }) async {
    if (!_reportIsInAdminScope(report)) {
      _errorMessage = 'This report is outside your assigned community.';
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.dismissReport(
        reportId: report.id,
        adminUid: adminUid,
        reason: reason,
      );
      await loadDashboardStats();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> issueUserWarningForReport({
    required ReportModel report,
    required String adminUid,
    required String message,
  }) async {
    if (!_reportIsInAdminScope(report)) {
      _errorMessage = 'This report is outside your assigned community.';
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.issueUserWarningForReport(
        reportId: report.id,
        adminUid: adminUid,
        message: message,
      );
      await loadDashboardStats();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboardStats() async {
    try {
      _dashboardStats = await _service.getAdminDashboardStats(
        communityId: _communityId,
        communityName: _communityName,
        includeAllCommunities: _includeAllCommunities,
      );
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

  void _handleStreamError(Object e) {
    _errorMessage = e.toString();
    notifyListeners();
  }

  void _refreshLocalDashboardStats() {
    final visibleReports = _visibleReports;
    final submitted = _verificationRequests
        .where(
          (request) => request.status == AppConstants.verificationSubmitted,
        )
        .length;
    final rejected = _verificationRequests
        .where((request) => request.status == AppConstants.verificationRejected)
        .length;
    final verified = _residents
        .where(
          (resident) =>
              resident.verificationStatus == AppConstants.verificationVerified,
        )
        .length;
    final activeListings =
        _listings
            .where((item) => item.status == AppConstants.itemStatusAvailable)
            .length +
        _visibleServices
            .where(
              (service) => service.status == AppConstants.serviceStatusActive,
            )
            .length;
    final openReports = visibleReports
        .where(
          (report) =>
              report.status.isEmpty ||
              report.status == AppConstants.reportStatusOpen ||
              report.status == AppConstants.reportStatusUnderReview,
        )
        .length;
    _dashboardStats = {
      ..._dashboardStats,
      'submittedRequests': submitted,
      'verifiedResidents': verified,
      'rejectedRequests': rejected,
      'totalUsers': _residents.length,
      'activeListings': activeListings,
      'openReports': openReports,
    };
    notifyListeners();
  }

  Set<String> get _communityResidentIds =>
      _residents.map((resident) => resident.uid).toSet();

  bool _belongsToVisibleResident(String firstId, [String secondId = '']) {
    if (_includeAllCommunities) return true;
    final residentIds = _communityResidentIds;
    if (residentIds.isEmpty) return false;
    return residentIds.contains(firstId) ||
        (secondId.isNotEmpty && residentIds.contains(secondId));
  }

  List<ServiceModel> get _visibleServices {
    if (_includeAllCommunities) return _services;
    return _services
        .where((service) => _belongsToVisibleResident(service.providerId))
        .toList();
  }

  List<ReportModel> get _visibleReports {
    if (_includeAllCommunities) return _reports;
    return _reports
        .where(
          (report) => _belongsToVisibleResident(
            report.reporterId,
            report.reportedUserId,
          ),
        )
        .toList();
  }

  List<BorrowRequest> get _visibleBorrowRequests {
    if (_includeAllCommunities) return _borrowRequests;
    return _borrowRequests
        .where(
          (request) =>
              _belongsToVisibleResident(request.ownerId, request.borrowerId),
        )
        .toList();
  }

  List<ServiceRequestModel> get _visibleServiceRequests {
    if (_includeAllCommunities) return _serviceRequests;
    return _serviceRequests
        .where(
          (request) => _belongsToVisibleResident(
            request.providerId,
            request.requesterId,
          ),
        )
        .toList();
  }

  bool _requestIsInAdminScope(VerificationRequest request) {
    if (_includeAllCommunities) return true;
    if (_communityId.isNotEmpty && request.communityId == _communityId) {
      return true;
    }
    if (_communityName.isNotEmpty && request.communityName == _communityName) {
      return true;
    }
    return false;
  }

  bool _reportIsInAdminScope(ReportModel report) {
    if (_includeAllCommunities) return true;
    return _belongsToVisibleResident(report.reporterId, report.reportedUserId);
  }

  @override
  void dispose() {
    _requestsSub?.cancel();
    _residentsSub?.cancel();
    _listingsSub?.cancel();
    _servicesSub?.cancel();
    _reportsSub?.cancel();
    _borrowRequestsSub?.cancel();
    _serviceRequestsSub?.cancel();
    super.dispose();
  }
}
