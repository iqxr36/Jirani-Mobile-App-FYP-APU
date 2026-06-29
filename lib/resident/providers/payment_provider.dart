import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/payment_method_model.dart';
import 'package:jirani/shared/services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentProvider({PaymentService? service})
    : _service = service ?? PaymentService();

  final PaymentService _service;

  bool _isLoading = false;
  String? _errorMessage;
  List<PaymentMethodModel> _paymentMethods = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PaymentMethodModel> get paymentMethods => _paymentMethods;

  Future<MarketplacePaymentSheetResult?> payMarketplaceBorrowRequest({
    required BorrowRequest request,
    required PaymentMethodModel paymentMethod,
  }) async {
    return _run(
      () => _service.presentMarketplacePaymentSheet(
        request: request,
        paymentMethod: paymentMethod,
      ),
    );
  }

  Future<void> loadPaymentMethods() async {
    final methods = await _run(_service.fetchPaymentMethods);
    if (methods != null) {
      _paymentMethods = methods;
      notifyListeners();
    }
  }

  Future<bool> addPaymentMethod() async {
    final result = await _run(() async {
      await _service.addPaymentMethod();
      return true;
    });
    if (result == true) {
      await loadPaymentMethods();
      return true;
    }
    return false;
  }

  Future<bool> deletePaymentMethod(String paymentMethodId) async {
    final result = await _run(() async {
      await _service.deletePaymentMethod(paymentMethodId);
      return true;
    });
    if (result == true) {
      await loadPaymentMethods();
      return true;
    }
    return false;
  }

  Future<bool> setDefaultPaymentMethod(String paymentMethodId) async {
    final result = await _run(() async {
      await _service.setDefaultPaymentMethod(paymentMethodId);
      return true;
    });
    if (result == true) {
      await loadPaymentMethods();
      return true;
    }
    return false;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

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

  static String _friendlyPaymentError(Object error) {
    if (error is StripeException) {
      return _friendlyStripeError(error);
    }

    if (error is FirebaseFunctionsException) {
      final message = error.message ?? '';
      if (message.contains('Stripe secret key is not configured')) {
        return 'Payment setup is not configured yet. Add STRIPE_SECRET_KEY to Firebase Functions and redeploy.';
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
    if (message.contains('Stripe secret key is not configured')) {
      return 'Payment setup is not configured yet. Add STRIPE_SECRET_KEY to Firebase Functions and redeploy.';
    }
    final firstLine = message.split('\n').first.trim();
    return firstLine.isEmpty ? 'Payment action failed. Please try again.' : firstLine;
  }

  static String _friendlyStripeError(StripeException error) {
    final code = _stripeFailureCode(error);
    if (code == FailureCode.Canceled) {
      return 'Payment cancelled. Your card was not charged.';
    }
    final underlying = error.error;
    final friendly = underlying.localizedMessage ?? underlying.message;
    if (friendly != null && friendly.trim().isNotEmpty) {
      return friendly;
    }
    final stripeCode = underlying.stripeErrorCode ?? underlying.declineCode;
    if (stripeCode != null && stripeCode.trim().isNotEmpty) {
      return 'Payment failed ($stripeCode). Please try a different card.';
    }
    return 'Payment could not complete. Please try again.';
  }

  static FailureCode _stripeFailureCode(StripeException error) {
    return error.error.code;
  }
}
