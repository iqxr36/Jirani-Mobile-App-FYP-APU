import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/services/borrow_request_service.dart';

// Marketplace borrow feature: owns borrower/lender request state for resident screens and delegates Firestore changes to BorrowRequestService.
class BorrowRequestProvider extends ChangeNotifier {
  BorrowRequestProvider({BorrowRequestService? service})
    : _service = service ?? BorrowRequestService();

  final BorrowRequestService _service;
  StreamSubscription<List<BorrowRequest>>? _mySub;
  StreamSubscription<List<BorrowRequest>>? _incomingSub;

  bool _isLoading = false;
  String? _errorMessage;
  List<BorrowRequest> _myBorrowRequests = const <BorrowRequest>[];
  List<BorrowRequest> _incomingRequests = const <BorrowRequest>[];
  BorrowRequest? _selectedRequest;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<BorrowRequest> get myBorrowRequests => _myBorrowRequests;
  List<BorrowRequest> get incomingRequests => _incomingRequests;
  BorrowRequest? get selectedRequest => _selectedRequest;

  // Marketplace borrow feature: loads one request for notification deep links and transaction detail refreshes.
  Future<BorrowRequest?> fetchBorrowRequest(String requestId) {
    return _service.fetchBorrowRequest(requestId);
  }

  // Marketplace borrow feature: streams all requests created by the signed-in borrower.
  void watchMyBorrowRequests(String borrowerId) {
    _mySub?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _mySub = _service
        .watchMyBorrowRequests(borrowerId)
        .listen(
          (data) {
            _myBorrowRequests = data;
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

  // Marketplace borrow feature: streams pending/active requests received by the lender for their listed items.
  void watchIncomingRequests(String ownerId) {
    _incomingSub?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _incomingSub = _service
        .watchIncomingRequests(ownerId)
        .listen(
          (data) {
            _incomingRequests = data;
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

  // Marketplace borrow feature: creates the initial pending request before owner approval and payment.
  Future<void> createBorrowRequest({
    required ItemModel item,
    required AppUser borrower,
    required DateTime requestedStartDate,
    required DateTime expectedReturnDate,
    required String pickupTime,
    required String message,
    double? usageFeeAmount,
    String rentalMode = '',
    int rentalUnitCount = 1,
    double? dailyRateSnapshot,
    double? hourlyRateSnapshot,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.createBorrowRequest(
        item: item,
        borrower: borrower,
        requestedStartDate: requestedStartDate,
        expectedReturnDate: expectedReturnDate,
        pickupTime: pickupTime,
        message: message,
        usageFeeAmount: usageFeeAmount,
        rentalMode: rentalMode,
        rentalUnitCount: rentalUnitCount,
        dailyRateSnapshot: dailyRateSnapshot,
        hourlyRateSnapshot: hourlyRateSnapshot,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marketplace borrow feature: lets the lender approve the request so the borrower can pay.
  Future<void> approveBorrowRequest({
    required String requestId,
    required String ownerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.approveBorrowRequest(
        requestId: requestId,
        ownerId: ownerId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marketplace borrow feature: lets the lender reject a request and stores the reason for the borrower.
  Future<void> rejectBorrowRequest({
    required String requestId,
    required String ownerId,
    required String rejectionReason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.rejectBorrowRequest(
        requestId: requestId,
        ownerId: ownerId,
        rejectionReason: rejectionReason,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marketplace borrow feature: lets the borrower cancel their own pending request before handover.
  Future<void> cancelBorrowRequest({
    required String requestId,
    required String borrowerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.cancelBorrowRequest(
        requestId: requestId,
        borrowerId: borrowerId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marketplace handover feature: borrower enters the handover code to say they are ready for pickup.
  Future<void> confirmPickupReady({
    required String requestId,
    required String borrowerId,
    required String handoverCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.confirmPickupReady(
        requestId: requestId,
        borrowerId: borrowerId,
        handoverCode: handoverCode,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marketplace handover feature: lender confirms pickup and optionally uploads before-handover proof.
  Future<void> confirmHandover({
    required String requestId,
    required String ownerId,
    required String conditionBefore,
    String? localProofPath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.confirmHandover(
        requestId: requestId,
        ownerId: ownerId,
        conditionBefore: conditionBefore,
        localProofPath: localProofPath,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marketplace return feature: borrower submits return notes and optional after-use proof.
  Future<void> submitReturn({
    required String requestId,
    required String borrowerId,
    required String returnNotes,
    String? localProofPath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.submitReturn(
        requestId: requestId,
        borrowerId: borrowerId,
        returnNotes: returnNotes,
        localProofPath: localProofPath,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marketplace return feature: lender accepts the returned item and records its final condition.
  Future<void> confirmReturn({
    required String requestId,
    required String ownerId,
    required String conditionAfter,
    required String ownerReturnNotes,
    String returnCode = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.confirmReturn(
        requestId: requestId,
        ownerId: ownerId,
        conditionAfter: conditionAfter,
        ownerReturnNotes: ownerReturnNotes,
        returnCode: returnCode,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marketplace deposit dispute feature: lender reports minor damage and requests a deposit deduction.
  Future<void> reportMinorIssue({
    required String requestId,
    required String ownerId,
    required double deductionAmount,
    required String reason,
    String? localProofPath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.reportMinorIssue(
        requestId: requestId,
        ownerId: ownerId,
        deductionAmount: deductionAmount,
        reason: reason,
        localProofPath: localProofPath,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marketplace deposit dispute feature: borrower accepts or disputes the lender's minor damage claim.
  Future<void> respondToMinorIssue({
    required String requestId,
    required String borrowerId,
    required bool accepted,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.respondToMinorIssue(
        requestId: requestId,
        borrowerId: borrowerId,
        accepted: accepted,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marketplace deposit dispute feature: lender reports major damage that can award the full deposit.
  Future<void> reportMajorDamage({
    required String requestId,
    required String ownerId,
    required String conditionAfter,
    required String description,
    required String localProofPath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.reportMajorDamage(
        requestId: requestId,
        ownerId: ownerId,
        conditionAfter: conditionAfter,
        description: description,
        localProofPath: localProofPath,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marketplace deposit feature: records the lender's normal-return decision before admin escalation is needed.
  Future<void> setDepositDecision({
    required String requestId,
    required String ownerId,
    required String decision,
    String reason = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.setDepositDecision(
        requestId: requestId,
        ownerId: ownerId,
        decision: decision,
        reason: reason,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marketplace UI state: remembers the currently opened request for detail screens.
  void selectRequest(BorrowRequest? request) {
    _selectedRequest = request;
    notifyListeners();
  }

  // Marketplace UI state: clears the latest request action error shown by resident screens.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _mySub?.cancel();
    _incomingSub?.cancel();
    super.dispose();
  }
}
