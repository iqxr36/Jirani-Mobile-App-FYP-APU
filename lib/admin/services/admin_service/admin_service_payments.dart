part of '../admin_service.dart';

mixin _AdminServicePaymentsMixin on _AdminServiceBase {
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
}
