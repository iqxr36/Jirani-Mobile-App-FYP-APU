import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/services/borrow_request_service.dart';

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

  Future<void> createBorrowRequest({
    required ItemModel item,
    required AppUser borrower,
    required DateTime requestedStartDate,
    required DateTime expectedReturnDate,
    required String pickupTime,
    required String message,
    double? usageFeeAmount,
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
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  Future<bool> completeManualPayment({
    required String requestId,
    required String borrowerId,
    String chatId = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.completeManualPayment(
        requestId: requestId,
        borrowerId: borrowerId,
        chatId: chatId,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmPickupReady({
    required String requestId,
    required String borrowerId,
    String? localProofPath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.confirmPickupReady(
        requestId: requestId,
        borrowerId: borrowerId,
        localProofPath: localProofPath,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmHandover({
    required String requestId,
    required String ownerId,
    required String conditionBefore,
    String handoverCode = '',
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
        handoverCode: handoverCode,
        localProofPath: localProofPath,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  void selectRequest(BorrowRequest? request) {
    _selectedRequest = request;
    notifyListeners();
  }

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
