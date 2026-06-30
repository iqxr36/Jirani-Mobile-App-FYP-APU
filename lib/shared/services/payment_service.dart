import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/marketplace_borrow_flow.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/models/payment_method_model.dart';

/// Marketplace payments result: returned after Stripe PaymentSheet finishes and the webhook status is checked.
class MarketplacePaymentSheetResult {
  const MarketplacePaymentSheetResult({
    required this.paymentId,
    required this.status,
  });

  final String paymentId;
  final String status;
}

/// Marketplace payments result: contains the backend-created PaymentIntent and customer data needed by PaymentSheet.
class MarketplacePaymentIntentResult {
  const MarketplacePaymentIntentResult({
    required this.clientSecret,
    required this.paymentId,
    required this.customerId,
    required this.ephemeralKey,
  });

  final String clientSecret;
  final String paymentId;
  final String customerId;
  final String ephemeralKey;
}

/// Saved cards result: contains the backend-created SetupIntent used to save a card through Stripe's secure UI.
class SetupIntentResult {
  const SetupIntentResult({
    required this.setupIntentClientSecret,
    required this.customerId,
    required this.ephemeralKey,
  });

  final String setupIntentClientSecret;
  final String customerId;
  final String ephemeralKey;
}

/// Stripe Connect model: describes whether a lender can receive automatic damage-deduction payouts.
class ConnectAccountStatus {
  const ConnectAccountStatus({
    required this.accountId,
    required this.status,
    required this.payoutsEnabled,
    required this.chargesEnabled,
    required this.transfersCapability,
    required this.detailsSubmitted,
    required this.requirementsDue,
    required this.disabledReason,
  });

  final String accountId;
  final String status;
  final bool payoutsEnabled;
  final bool chargesEnabled;
  final String transfersCapability;
  final bool detailsSubmitted;
  final List<String> requirementsDue;
  final String disabledReason;

  bool get isComplete => status == AppConstants.stripeConnectStatusComplete;
  bool get hasStarted => accountId.trim().isNotEmpty;

  /// Stripe Connect feature: maps backend account status into UI-friendly payout setup flags.
  factory ConnectAccountStatus.fromJson(Map<String, dynamic> data) {
    final rawRequirements = data['requirementsDue'];
    return ConnectAccountStatus(
      accountId: _connectReadString(data, 'accountId'),
      status: _connectReadString(
        data,
        'status',
        fallback: AppConstants.stripeConnectStatusNotStarted,
      ),
      payoutsEnabled: data['payoutsEnabled'] == true,
      chargesEnabled: data['chargesEnabled'] == true,
      transfersCapability: _connectReadString(data, 'transfersCapability'),
      detailsSubmitted: data['detailsSubmitted'] == true,
      requirementsDue: rawRequirements is List
          ? rawRequirements.whereType<String>().toList(growable: false)
          : const [],
      disabledReason: _connectReadString(data, 'disabledReason'),
    );
  }
}

/// Stripe Connect feature: safely reads optional string fields from callable function responses.
String _connectReadString(
  Map<String, dynamic> data,
  String key, {
  String fallback = '',
}) {
  final value = data[key];
  return value is String ? value : fallback;
}

/// Stripe Connect result: returns the hosted onboarding URL and latest lender payout status.
class ConnectOnboardingLinkResult {
  const ConnectOnboardingLinkResult({
    required this.url,
    required this.status,
  });

  final String url;
  final ConnectAccountStatus status;
}

/// Payments feature service: wraps Firebase callable functions and Stripe PaymentSheet for marketplace payments and saved cards.
class PaymentService {
  PaymentService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Marketplace payments: asks the backend to validate the borrow request and create a Stripe PaymentIntent.
  Future<MarketplacePaymentIntentResult> createMarketplacePaymentIntent({
    required BorrowRequest request,
    required PaymentMethodModel paymentMethod,
  }) async {
    final amount = marketplaceAmountInMinorUnits(request);
    if (amount <= 0) {
      throw Exception('No payment is required for this request.');
    }

    final callable = _functions.httpsCallable('createPaymentIntent');
    final result = await callable.call<Map<String, dynamic>>({
      'amount': amount,
      'currency': AppConstants.defaultPaymentCurrency,
      'paymentType': AppConstants.paymentTypeMarketplace,
      'relatedId': request.id,
      'payerId': request.borrowerId,
      'receiverId': request.ownerId,
      'itemId': request.itemId,
      'paymentMethodId': paymentMethod.stripePaymentMethodId,
      'description': 'Jirani marketplace payment for ${request.itemTitle}',
    });
    final data = _asMap(result.data);
    return MarketplacePaymentIntentResult(
      clientSecret: _readString(data, 'clientSecret'),
      paymentId: _readString(data, 'paymentId'),
      customerId: _readString(data, 'customerId'),
      ephemeralKey: _readString(data, 'ephemeralKey'),
    );
  }

  /// Marketplace payments: opens Stripe PaymentSheet for an approved borrow request using the resident's selected card.
  Future<MarketplacePaymentSheetResult> presentMarketplacePaymentSheet({
    required BorrowRequest request,
    required PaymentMethodModel paymentMethod,
  }) async {
    _ensurePublishableKey();
    final intent = await createMarketplacePaymentIntent(
      request: request,
      paymentMethod: paymentMethod,
    );

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: AppConstants.appName,
        paymentIntentClientSecret: intent.clientSecret,
        customerId: intent.customerId,
        customerEphemeralKeySecret: intent.ephemeralKey,
        allowsDelayedPaymentMethods: false,
        primaryButtonLabel: 'Pay ${_formatAmountForButton(request)}',
        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'MY',
          currencyCode: 'MYR',
          testEnv: true,
        ),
      ),
    );

    try {
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      if (_isUserCancellation(e)) {
        return MarketplacePaymentSheetResult(
          paymentId: intent.paymentId,
          status: AppConstants.paymentStatusFlowCancelled,
        );
      }
      rethrow;
    }

    final status = await _waitForWebhookConfirmation(intent.paymentId);
    return MarketplacePaymentSheetResult(
      paymentId: intent.paymentId,
      status: status,
    );
  }

  /// Polls Firestore briefly so the UI doesn't see the brief window where
  /// Stripe has charged but the webhook hasn't updated the doc yet.
  Future<String> _waitForWebhookConfirmation(String paymentId) async {
    const maxAttempts = 6;
    const pollDelay = Duration(milliseconds: 1200);
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
        // Transient error — try again.
      }
    }
    return AppConstants.paymentStatusPending;
  }

  /// Marketplace payments: identifies when the resident closed PaymentSheet without completing payment.
  static bool _isUserCancellation(StripeException e) {
    return e.error.code == FailureCode.Canceled;
  }

  /// Saved cards: asks the backend to create a SetupIntent for the current Firebase user and Stripe customer.
  Future<SetupIntentResult> createSetupIntent() async {
    _ensurePublishableKey();
    final result = await _functions
        .httpsCallable('createSetupIntent')
        .call<Map<String, dynamic>>();
    final data = _asMap(result.data);
    return SetupIntentResult(
      setupIntentClientSecret: _readString(data, 'setupIntentClientSecret'),
      customerId: _readString(data, 'customerId'),
      ephemeralKey: _readString(data, 'ephemeralKey'),
    );
  }

  /// Saved cards: presents Stripe's secure card-saving sheet so Flutter never handles raw card details.
  Future<void> addPaymentMethod() async {
    final setupIntent = await createSetupIntent();
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: AppConstants.appName,
        setupIntentClientSecret: setupIntent.setupIntentClientSecret,
        customerId: setupIntent.customerId,
        customerEphemeralKeySecret: setupIntent.ephemeralKey,
        allowsDelayedPaymentMethods: false,
        primaryButtonLabel: 'Save Card',
        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'MY',
          currencyCode: 'MYR',
          testEnv: true,
          label: 'Save card',
          amount: '0',
        ),
      ),
    );
    await Stripe.instance.presentPaymentSheet();
  }

  /// Saved cards: loads safe saved-card metadata from the backend for the Payment Methods screen.
  Future<List<PaymentMethodModel>> fetchPaymentMethods() async {
    final result = await _functions
        .httpsCallable('listPaymentMethods')
        .call<Map<String, dynamic>>();
    final data = _asMap(result.data);
    final rawMethods = data['paymentMethods'];
    if (rawMethods is! List) return const [];
    return rawMethods
        .whereType<Map>()
        .map((item) => PaymentMethodModel.fromJson(_asMap(item)))
        .toList(growable: false);
  }

  /// Saved cards: asks the backend to detach a card after verifying it belongs to this user's Stripe customer.
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    await _functions.httpsCallable('deletePaymentMethod').call<void>({
      'paymentMethodId': paymentMethodId,
    });
  }

  /// Saved cards: asks the backend to make one saved card the Stripe customer default.
  Future<void> setDefaultPaymentMethod(String paymentMethodId) async {
    await _functions.httpsCallable('setDefaultPaymentMethod').call<void>({
      'paymentMethodId': paymentMethodId,
    });
  }

  /// Marketplace payments: reads the backend payment record status after Stripe webhooks update Firestore.
  Future<String> getPaymentStatus(String paymentId) async {
    final result = await _functions.httpsCallable('getPaymentStatus').call({
      'paymentId': paymentId,
    });
    final data = _asMap(result.data);
    return _readString(data, 'status', fallback: AppConstants.paymentStatusPending);
  }

  /// Stripe Connect payouts: fetches whether the lender has completed onboarding for automatic payouts.
  Future<ConnectAccountStatus> getConnectAccountStatus() async {
    final result = await _functions
        .httpsCallable('getConnectAccountStatus')
        .call<Map<String, dynamic>>();
    return ConnectAccountStatus.fromJson(_asMap(result.data));
  }

  /// Stripe Connect payouts: creates a hosted onboarding link so a lender can receive damage deduction transfers.
  Future<ConnectOnboardingLinkResult> createConnectOnboardingLink({
    required String returnUrl,
    required String refreshUrl,
  }) async {
    final result = await _functions
        .httpsCallable('createConnectOnboardingLink')
        .call<Map<String, dynamic>>({
      'returnUrl': returnUrl,
      'refreshUrl': refreshUrl,
    });
    final data = _asMap(result.data);
    return ConnectOnboardingLinkResult(
      url: _readString(data, 'url'),
      status: ConnectAccountStatus.fromJson(data),
    );
  }

  /// Marketplace payments: converts fee plus deposit from RM to Stripe minor units (sen).
  static int marketplaceAmountInMinorUnits(BorrowRequest request) {
    final total = MarketplaceBorrowFlow.totalDue(
      usageFee: request.usageFeeAmount,
      deposit: request.depositAmount,
    );
    return max(0, (total * 100).round());
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

  /// Marketplace payments UI: formats the PaymentSheet primary button amount from the borrow request total.
  static String _formatAmountForButton(BorrowRequest request) {
    final total = PaymentService.marketplaceAmountInMinorUnits(request) / 100;
    return 'RM ${total.toStringAsFixed(total % 1 == 0 ? 0 : 2)}';
  }

  /// Payments security: confirms Flutter has only the Stripe publishable key, while the secret key stays in Functions.
  static void _ensurePublishableKey() {
    const publishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
    if (publishableKey.trim().isEmpty) {
      throw Exception(
        'Stripe publishable key is missing. Start Flutter with '
        '--dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxxxx.',
      );
    }
  }
}
