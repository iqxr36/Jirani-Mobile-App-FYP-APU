// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : payment_service.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Monday,29-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/marketplace_borrow_flow.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/service_request_model.dart';

/// Marketplace payments result: returned after Xendit hosted checkout is opened.
class MarketplacePaymentResult {
  const MarketplacePaymentResult({
    required this.paymentId,
    required this.status,
    required this.checkoutUrl,
  });

  final String paymentId;
  final String status;
  final String checkoutUrl;
}

/// Service escrow payment result: returned after Xendit hosted checkout is opened.
class ServicePaymentResult {
  const ServicePaymentResult({
    required this.paymentId,
    required this.status,
    required this.checkoutUrl,
  });

  final String paymentId;
  final String status;
  final String checkoutUrl;
}

/// Marketplace payment service: wraps Firebase callables for Xendit hosted checkout and status polling.
class PaymentService {
  PaymentService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Marketplace payments: asks the backend to validate the borrow request and create a Xendit hosted checkout.
  Future<MarketplacePaymentResult> createXenditMarketplacePayment({
    required BorrowRequest request,
    required String successRedirectUrl,
    required String failureRedirectUrl,
  }) async {
    final amount = marketplaceAmountInMinorUnits(request);
    if (amount <= 0) {
      throw Exception('No payment is required for this request.');
    }

    final callable = _functions.httpsCallable('createXenditMarketplacePayment');
    final result = await callable.call<Map<String, dynamic>>({
      'amount': amount,
      'currency': AppConstants.defaultPaymentCurrency,
      'paymentType': AppConstants.paymentTypeMarketplace,
      'relatedId': request.id,
      'payerId': request.borrowerId,
      'receiverId': request.ownerId,
      'itemId': request.itemId,
      'description': 'Jirani marketplace payment for ${request.itemTitle}',
      'successRedirectUrl': successRedirectUrl,
      'failureRedirectUrl': failureRedirectUrl,
    });
    final data = _asMap(result.data);
    return MarketplacePaymentResult(
      paymentId: _readString(data, 'paymentId'),
      status: _readString(
        data,
        'status',
        fallback: AppConstants.paymentStatusPending,
      ),
      checkoutUrl: _readString(data, 'checkoutUrl'),
    );
  }

  /// Service payments: creates a Xendit checkout for an accepted paid service request.
  Future<ServicePaymentResult> createXenditServicePayment({
    required ServiceRequestModel request,
    required String successRedirectUrl,
    required String failureRedirectUrl,
  }) async {
    final amount = serviceAmountInMinorUnits(request);
    if (amount <= 0) {
      throw Exception('No payment is required for this service.');
    }

    final callable = _functions.httpsCallable('createXenditServicePayment');
    final result = await callable.call<Map<String, dynamic>>({
      'amount': amount,
      'currency': AppConstants.defaultPaymentCurrency,
      'paymentType': AppConstants.paymentTypeService,
      'relatedId': request.id,
      'payerId': request.requesterId,
      'receiverId': request.providerId,
      'serviceId': request.serviceId,
      'description': 'Jirani service payment for ${request.serviceTitle}',
      'successRedirectUrl': successRedirectUrl,
      'failureRedirectUrl': failureRedirectUrl,
    });
    final data = _asMap(result.data);
    return ServicePaymentResult(
      paymentId: _readString(data, 'paymentId'),
      status: _readString(
        data,
        'status',
        fallback: AppConstants.paymentStatusPending,
      ),
      checkoutUrl: _readString(data, 'checkoutUrl'),
    );
  }

  /// Marketplace payments: reads the backend payment record status after Xendit webhooks update Firestore.
  Future<String> getPaymentStatus(String paymentId) async {
    final result = await _functions.httpsCallable('getPaymentStatus').call({
      'paymentId': paymentId,
    });
    final data = _asMap(result.data);
    return _readString(data, 'status', fallback: AppConstants.paymentStatusPending);
  }

  /// Polls Firestore briefly so the UI can show a useful state while the Xendit webhook arrives.
  Future<String> waitForPaymentConfirmation(String paymentId) async {
    const maxAttempts = 8;
    const pollDelay = Duration(milliseconds: 1500);
    const terminalStatuses = <String>{
      AppConstants.paymentStatusSucceeded,
      AppConstants.paymentStatusFailed,
      AppConstants.paymentStatusCancelled,
    };

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(pollDelay);
      try {
        final status = await getPaymentStatus(paymentId);
        if (terminalStatuses.contains(status)) return status;
      } catch (_) {
        // Transient error, try again while the hosted checkout returns.
      }
    }
    return AppConstants.paymentStatusPending;
  }

  /// Marketplace payments: converts fee plus deposit from RM to Xendit minor units for backend validation.
  static int marketplaceAmountInMinorUnits(BorrowRequest request) {
    final total = MarketplaceBorrowFlow.totalDue(
      usageFee: request.usageFeeAmount,
      deposit: request.depositAmount,
    );
    return max(0, (total * 100).round());
  }

  /// Service payments: converts the agreed RM amount to Xendit minor units.
  static int serviceAmountInMinorUnits(ServiceRequestModel request) {
    final amount = request.amount ?? 0;
    return max(0, (amount * 100).round());
  }

  /// Payments feature: normalizes callable function response data into a Dart map.
  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  /// Payments feature: safely reads string values from backend responses with a fallback.
  static String _readString(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final value = data[key];
    return value is String ? value : fallback;
  }
}
