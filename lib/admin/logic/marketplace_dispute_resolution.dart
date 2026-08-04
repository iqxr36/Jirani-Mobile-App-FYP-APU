// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : marketplace_dispute_resolution.dart (Dart source file)
// Description     : Jirani - selects the correct deposit outcome for marketplace admin disputes.
// First Written on: Wednesday,22-July-2026
// Last Edited on  : Wednesday,22-July-2026

import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/borrow_request.dart';

/// Marketplace admin dispute: the deposit decision and amount that must be
/// sent to the backend or recorded for a legacy transaction.
class MarketplaceDisputeDepositResolution {
  const MarketplaceDisputeDepositResolution({
    required this.resolutionDecision,
    required this.damageDeductionAmount,
    required this.borrowerRefundAmount,
    required this.depositDecision,
    required this.damageDecision,
    required this.isMinorDamageDeduction,
  });

  final String resolutionDecision;
  final double damageDeductionAmount;
  final double borrowerRefundAmount;
  final String depositDecision;
  final String damageDecision;
  final bool isMinorDamageDeduction;
}

/// Marketplace admin dispute: prevents a minor-damage lender resolution from
/// being converted into a full-deposit deduction.
MarketplaceDisputeDepositResolution marketplaceDisputeDepositResolutionFor({
  required BorrowRequest request,
  required bool resolveForBorrower,
}) {
  final depositAmount = request.depositAmount ?? 0.0;

  if (resolveForBorrower) {
    return MarketplaceDisputeDepositResolution(
      resolutionDecision: AppConstants.depositResolutionFullRefund,
      damageDeductionAmount: 0,
      borrowerRefundAmount: depositAmount > 0 ? depositAmount : 0,
      depositDecision: AppConstants.depositDecisionReturnDeposit,
      damageDecision: AppConstants.damageDecisionAdminFullRefund,
      isMinorDamageDeduction: false,
    );
  }

  if (request.itemConditionAfter == AppConstants.borrowConditionAfterMinor) {
    final requestedDeduction = request.minorDeductionAmount;
    if (depositAmount <= 0 ||
        requestedDeduction == null ||
        requestedDeduction <= 0 ||
        requestedDeduction >= depositAmount) {
      throw MarketplaceDisputeResolutionException(
        'The minor-damage deduction must be greater than RM 0 and less than '
        'the deposit. Review the transaction before resolving it.',
      );
    }
    return MarketplaceDisputeDepositResolution(
      resolutionDecision: AppConstants.depositResolutionPartialDeduction,
      damageDeductionAmount: requestedDeduction,
      borrowerRefundAmount: depositAmount - requestedDeduction,
      depositDecision: AppConstants.depositDecisionPartialDeduction,
      damageDecision: AppConstants.damageDecisionAdminPartialDeduction,
      isMinorDamageDeduction: true,
    );
  }

  final fullDeduction = depositAmount > 0 ? depositAmount : 0.0;
  return MarketplaceDisputeDepositResolution(
    resolutionDecision: AppConstants.depositResolutionFullDeduction,
    damageDeductionAmount: fullDeduction,
    borrowerRefundAmount: 0,
    depositDecision: AppConstants.depositDecisionWithholdDeposit,
    damageDecision: AppConstants.damageDecisionAdminFullDeduction,
    isMinorDamageDeduction: false,
  );
}

class MarketplaceDisputeResolutionException implements Exception {
  const MarketplaceDisputeResolutionException(this.message);

  final String message;

  @override
  String toString() => message;
}
