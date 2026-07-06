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

// Admin portal feature: coordinates dashboard state, scoped realtime streams, verification, reports, residents, and payout actions.
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

  // Admin portal feature: configures community scope from the signed-in admin before starting streams.
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

  // Admin verification feature: streams verification requests for the selected status and admin community scope.
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

  // Admin verification feature: loads one request for the review detail screen.
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

  // Admin dashboard feature: starts all realtime collections used by overview, reports, listings, residents, and transactions.
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

  // Admin verification feature: approves a resident proof request and refreshes dashboard counts.
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

  // Admin verification feature: rejects a resident proof request with an admin reason.
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

  // Admin reports feature: resolves a marketplace complaint/dispute for borrower or lender.
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

  // Admin reports feature: closes a report without taking further action.
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

  // Admin reports feature: sends a warning notification to the reported resident.
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

  // Admin deposit feature: decides how much of a disputed deposit is refunded or awarded to the lender.
  Future<void> resolveMarketplaceDeposit({
    required BorrowRequest borrowRequest,
    required String decision,
    required double damageDeductionAmount,
    required String reason,
    String reportId = '',
  }) async {
    if (!_belongsToVisibleResident(
      borrowRequest.ownerId,
      borrowRequest.borrowerId,
    )) {
      _errorMessage = 'This transaction is outside your assigned community.';
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.resolveMarketplaceDeposit(
        borrowRequestId: borrowRequest.id,
        decision: decision,
        damageDeductionAmount: damageDeductionAmount,
        reason: reason,
        reportId: reportId,
      );
      await loadDashboardStats();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin payout feature: marks a manual lender payout as paid after the lender collects it from admin.
  Future<void> markManualPayoutPaid({
    required BorrowRequest borrowRequest,
    required String reference,
    String note = '',
  }) async {
    if (!_belongsToVisibleResident(
      borrowRequest.ownerId,
      borrowRequest.borrowerId,
    )) {
      _errorMessage = 'This payout is outside your assigned community.';
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.markManualPayoutPaid(
        borrowRequestId: borrowRequest.id,
        manualPayoutReference: reference,
        manualPayoutNote: note,
      );
      await loadDashboardStats();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> forceServicePayout({
    required ServiceRequestModel serviceRequest,
    required String reason,
  }) async {
    if (!_belongsToVisibleResident(
      serviceRequest.providerId,
      serviceRequest.requesterId,
    )) {
      _errorMessage = 'This service dispute is outside your assigned community.';
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.forceServicePayout(
        serviceRequestId: serviceRequest.id,
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

  Future<void> refundServicePayment({
    required ServiceRequestModel serviceRequest,
    required String reason,
  }) async {
    if (!_belongsToVisibleResident(
      serviceRequest.providerId,
      serviceRequest.requesterId,
    )) {
      _errorMessage = 'This service dispute is outside your assigned community.';
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.refundServicePayment(
        serviceRequestId: serviceRequest.id,
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

  // Admin residents feature: updates resident profile/contact/community fields.
  Future<bool> updateResidentDetails({
    required AppUser resident,
    required String adminUid,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String unitNumber,
    required String communityId,
    required String communityName,
  }) {
    return _runResidentAction(
      resident,
      () => _service.updateResidentDetails(
        residentUid: resident.uid,
        adminUid: adminUid,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        unitNumber: unitNumber,
        communityId: communityId,
        communityName: communityName,
      ),
    );
  }

  // Admin residents feature: suspends a resident and blocks normal app access.
  Future<bool> suspendResident({
    required AppUser resident,
    required String adminUid,
    required String reason,
  }) {
    return _runResidentAction(
      resident,
      () => _service.suspendResident(
        residentUid: resident.uid,
        adminUid: adminUid,
        reason: reason,
      ),
    );
  }

  // Admin residents feature: reactivates a previously suspended resident.
  Future<bool> reactivateResident({
    required AppUser resident,
    required String adminUid,
  }) {
    return _runResidentAction(
      resident,
      () => _service.reactivateResident(
        residentUid: resident.uid,
        adminUid: adminUid,
      ),
    );
  }

  // Admin residents feature: archives a resident account while preserving history.
  Future<bool> archiveResident({
    required AppUser resident,
    required String adminUid,
    required String reason,
  }) {
    return _runResidentAction(
      resident,
      () => _service.archiveResident(
        residentUid: resident.uid,
        adminUid: adminUid,
        reason: reason,
      ),
    );
  }

  // Admin residents feature: restores an archived resident account.
  Future<bool> unarchiveResident({
    required AppUser resident,
    required String adminUid,
  }) {
    return _runResidentAction(
      resident,
      () => _service.unarchiveResident(
        residentUid: resident.uid,
        adminUid: adminUid,
      ),
    );
  }

  // Admin residents feature: resets a resident's verification so they must submit proof again.
  Future<bool> resetResidentVerification({
    required AppUser resident,
    required String adminUid,
    required String reason,
  }) {
    return _runResidentAction(
      resident,
      () => _service.resetResidentVerification(
        residentUid: resident.uid,
        adminUid: adminUid,
        reason: reason,
      ),
    );
  }

  // Admin residents feature: manually overrides a resident verification status.
  Future<bool> overrideResidentVerification({
    required AppUser resident,
    required String adminUid,
    required String status,
    required String reason,
  }) {
    return _runResidentAction(
      resident,
      () => _service.overrideResidentVerification(
        residentUid: resident.uid,
        adminUid: adminUid,
        status: status,
        reason: reason,
      ),
    );
  }

  // Admin residents feature: sends a direct admin notice notification to one resident.
  Future<bool> sendResidentNotice({
    required AppUser resident,
    required String adminUid,
    required String title,
    required String message,
  }) {
    return _runResidentAction(
      resident,
      () => _service.sendResidentNotice(
        residentUid: resident.uid,
        adminUid: adminUid,
        title: title,
        message: message,
      ),
    );
  }

  // Admin listings feature: archives a marketplace item so residents no longer see it.
  Future<bool> archiveMarketplaceItem({
    required ItemModel item,
    required String adminUid,
    required String reason,
  }) {
    return _runListingAction(
      ownerId: item.ownerId,
      action: () => _service.archiveMarketplaceItem(
        itemId: item.id,
        adminUid: adminUid,
        reason: reason,
      ),
    );
  }

  // Admin listings feature: restores an archived marketplace item when no active borrow is attached.
  Future<bool> restoreMarketplaceItem({
    required ItemModel item,
    required String adminUid,
    required String reason,
  }) {
    return _runListingAction(
      ownerId: item.ownerId,
      action: () => _service.restoreMarketplaceItem(
        itemId: item.id,
        adminUid: adminUid,
        reason: reason,
      ),
    );
  }

  // Admin listings feature: archives a task service so residents no longer see it.
  Future<bool> archiveTaskService({
    required ServiceModel service,
    required String adminUid,
    required String reason,
  }) {
    return _runListingAction(
      ownerId: service.providerId,
      action: () => _service.archiveTaskService(
        serviceId: service.id,
        adminUid: adminUid,
        reason: reason,
      ),
    );
  }

  // Admin listings feature: restores an archived task service.
  Future<bool> restoreTaskService({
    required ServiceModel service,
    required String adminUid,
    required String reason,
  }) {
    return _runListingAction(
      ownerId: service.providerId,
      action: () => _service.restoreTaskService(
        serviceId: service.id,
        adminUid: adminUid,
        reason: reason,
      ),
    );
  }

  // Admin dashboard feature: fetches aggregate counts from Firestore for dashboard cards.
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

  // Admin verification feature: changes the verification inbox filter and restarts the request stream.
  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    watchVerificationRequests(status: status);
  }

  // Admin UI state: clears the latest portal error after it is shown.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Admin UI state: stores realtime stream failures for SnackBars or inline errors.
  void _handleStreamError(Object e) {
    _errorMessage = e.toString();
    notifyListeners();
  }

  // Admin residents feature: enforces admin community scope and wraps resident mutations with loading/error state.
  Future<bool> _runResidentAction(
    AppUser resident,
    Future<void> Function() action,
  ) async {
    if (!_residentIsInAdminScope(resident)) {
      _errorMessage = 'This resident is outside your assigned community.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      await loadDashboardStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin listings feature: enforces community scope and wraps listing moderation mutations.
  Future<bool> _runListingAction({
    required String ownerId,
    required Future<void> Function() action,
  }) async {
    if (!_belongsToVisibleResident(ownerId)) {
      _errorMessage = 'This listing is outside your assigned community.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      await loadDashboardStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin dashboard feature: recomputes visible counts from current realtime lists.
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

  // Admin scoping feature: caches the resident IDs visible to this admin's community.
  Set<String> get _communityResidentIds =>
      _residents.map((resident) => resident.uid).toSet();

  // Admin scoping feature: checks whether either related resident belongs to the admin's visible community.
  bool _belongsToVisibleResident(String firstId, [String secondId = '']) {
    if (_includeAllCommunities) return true;
    final residentIds = _communityResidentIds;
    if (residentIds.isEmpty) return false;
    return residentIds.contains(firstId) ||
        (secondId.isNotEmpty && residentIds.contains(secondId));
  }

  // Admin scoping feature: filters services to this admin's community unless they are a system admin.
  List<ServiceModel> get _visibleServices {
    if (_includeAllCommunities) return _services;
    return _services
        .where((service) => _belongsToVisibleResident(service.providerId))
        .toList();
  }

  // Admin scoping feature: filters reports to visible residents for community admins.
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

  // Admin scoping feature: filters marketplace transactions to visible residents for community admins.
  List<BorrowRequest> get _visibleBorrowRequests {
    if (_includeAllCommunities) return _borrowRequests;
    return _borrowRequests
        .where(
          (request) =>
              _belongsToVisibleResident(request.ownerId, request.borrowerId),
        )
        .toList();
  }

  // Admin scoping feature: filters service requests to visible residents for community admins.
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

  // Admin scoping feature: verifies a verification request belongs to the admin's community.
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

  // Admin scoping feature: verifies a report involves a resident visible to this admin.
  bool _reportIsInAdminScope(ReportModel report) {
    if (_includeAllCommunities) return true;
    return _belongsToVisibleResident(report.reporterId, report.reportedUserId);
  }

  // Admin scoping feature: verifies a resident belongs to the admin's community before mutation.
  bool _residentIsInAdminScope(AppUser resident) {
    if (_includeAllCommunities) return true;
    if (_communityId.isNotEmpty && resident.communityId == _communityId) {
      return true;
    }
    if (_communityName.isNotEmpty &&
        resident.communityName == _communityName) {
      return true;
    }
    return false;
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
