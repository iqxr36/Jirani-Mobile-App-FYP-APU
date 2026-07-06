import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/service_request_model.dart';
import 'package:jirani/shared/services/payment_service.dart';

/// Payments state manager: exposes Xendit hosted checkout actions to resident screens.
class PaymentProvider extends ChangeNotifier {
  PaymentProvider({PaymentService? service})
    : _service = service ?? PaymentService();

  final PaymentService _service;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Marketplace payments: creates a Xendit hosted checkout for an approved borrow request.
  Future<MarketplacePaymentResult?> createXenditMarketplacePayment({
    required BorrowRequest request,
    required String successRedirectUrl,
    required String failureRedirectUrl,
  }) {
    return _run(
      () => _service.createXenditMarketplacePayment(
        request: request,
        successRedirectUrl: successRedirectUrl,
        failureRedirectUrl: failureRedirectUrl,
      ),
    );
  }

  /// Service payments: creates a Xendit hosted checkout for an accepted service request.
  Future<ServicePaymentResult?> createXenditServicePayment({
    required ServiceRequestModel request,
    required String successRedirectUrl,
    required String failureRedirectUrl,
  }) {
    return _run(
      () => _service.createXenditServicePayment(
        request: request,
        successRedirectUrl: successRedirectUrl,
        failureRedirectUrl: failureRedirectUrl,
      ),
    );
  }

  /// Marketplace payments: polls backend status after the hosted checkout returns.
  Future<String?> waitForPaymentConfirmation(String paymentId) {
    return _run(() => _service.waitForPaymentConfirmation(paymentId));
  }

  /// Payments UI: clears the current user-facing error before a retry or screen refresh.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Payments state manager: wraps async actions with loading, error capture, and listener notifications.
  Future<T?> _run<T>(Future<T> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } catch (error) {
      _errorMessage = _friendlyPaymentError(error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Payments UX: converts Firebase Functions exceptions into resident-friendly messages.
  static String _friendlyPaymentError(Object error) {
    if (error is FirebaseFunctionsException) {
      final message = error.message ?? '';
      if (message.contains('Xendit secret key is not configured')) {
        return 'Payment setup is not configured yet. Add XENDIT_SECRET_KEY to Firebase Functions and redeploy.';
      }
      if (error.code == 'unauthenticated') {
        return 'Please sign in again before managing payments.';
      }
      if (error.code == 'permission-denied') {
        return 'You do not have permission to use this payment action.';
      }
      if (message.trim().isNotEmpty) return message;
      return 'Payment action failed. Please try again.';
    }

    final message = error.toString().replaceFirst('Exception: ', '').trim();
    final firstLine = message.split('\n').first.trim();
    return firstLine.isEmpty ? 'Payment action failed. Please try again.' : firstLine;
  }
}
