part of '../admin_service.dart';

// Admin payments feature: calls backend Functions for deposit refunds/deductions and manual payout state.
mixin _AdminServicePaymentsMixin on _AdminServiceBase {
  // Admin payments feature: calls the backend to refund borrower deposit, deduct damage, and prepare lender earnings.
  Future<void> resolveMarketplaceDeposit({
    required String borrowRequestId,
    required String decision,
    required double damageDeductionAmount,
    required String reason,
    String reportId = '',
  }) async {
    if (borrowRequestId.trim().isEmpty) {
      throw Exception('Transaction ID is missing.');
    }
    if (reason.trim().isEmpty) {
      throw Exception('Resolution reason is required.');
    }

    final callable = _functions.httpsCallable('resolveMarketplaceDeposit');
    await callable.call<void>({
      'borrowRequestId': borrowRequestId.trim(),
      'decision': decision,
      'damageDeductionAmount': damageDeductionAmount,
      'reason': reason.trim(),
      'reportId': reportId.trim(),
    });
  }

  // Admin payouts feature: marks a manual lender payout as collected and notifies the lender.
  Future<void> markManualPayoutPaid({
    required String borrowRequestId,
    required String manualPayoutReference,
    String manualPayoutNote = '',
  }) async {
    if (borrowRequestId.trim().isEmpty) {
      throw Exception('Transaction ID is missing.');
    }
    final callable = _functions.httpsCallable('markManualPayoutPaid');
    await callable.call<void>({
      'borrowRequestId': borrowRequestId.trim(),
      'manualPayoutReference': manualPayoutReference.trim(),
      'manualPayoutNote': manualPayoutNote.trim(),
    });
  }

  Future<int> repairStuckMarketplaceSettlement({
    String borrowRequestId = '',
  }) async {
    final callable = _functions.httpsCallable('repairStuckMarketplaceSettlement');
    final result = await callable.call<Map<String, dynamic>>({
      if (borrowRequestId.trim().isNotEmpty)
        'borrowRequestId': borrowRequestId.trim(),
    });
    final data = result.data;
    final repaired = data['repairedCount'];
    if (repaired is int) return repaired;
    if (repaired is num) return repaired.toInt();
    return 0;
  }

  Future<void> forceServicePayout({
    required String serviceRequestId,
    required String reason,
  }) async {
    if (serviceRequestId.trim().isEmpty) {
      throw Exception('Service request ID is missing.');
    }
    if (reason.trim().isEmpty) {
      throw Exception('Resolution reason is required.');
    }
    final callable = _functions.httpsCallable('forceServicePayout');
    await callable.call<void>({
      'requestId': serviceRequestId.trim(),
      'reason': reason.trim(),
    });
  }

  Future<void> refundServicePayment({
    required String serviceRequestId,
    required String reason,
  }) async {
    if (serviceRequestId.trim().isEmpty) {
      throw Exception('Service request ID is missing.');
    }
    if (reason.trim().isEmpty) {
      throw Exception('Resolution reason is required.');
    }
    final callable = _functions.httpsCallable('refundServicePayment');
    await callable.call<void>({
      'requestId': serviceRequestId.trim(),
      'reason': reason.trim(),
    });
  }
}
