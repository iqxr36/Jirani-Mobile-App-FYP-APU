import 'dart:math';

import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/borrow_request.dart';

class MarketplaceBorrowFlow {
  MarketplaceBorrowFlow._();

  static int dailyDurationDays(DateTime start, DateTime end) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    final rawDays = normalizedEnd.difference(normalizedStart).inDays + 1;
    return max(1, rawDays);
  }

  static double dailyUsageFee({
    required double dailyFee,
    required DateTime start,
    required DateTime end,
  }) {
    return dailyFee * dailyDurationDays(start, end);
  }

  static double totalDue({double? usageFee, double? deposit}) {
    return max(0.0, usageFee ?? 0.0) + max(0.0, deposit ?? 0.0);
  }

  static bool isPaymentComplete(BorrowRequest request) {
    return request.paymentStatus == AppConstants.paymentStatusCompleted;
  }

  static bool canCompleteManualPayment({
    required BorrowRequest request,
    required String borrowerId,
  }) {
    return request.borrowerId == borrowerId &&
        request.status == AppConstants.borrowStatusApproved &&
        !isPaymentComplete(request);
  }

  static bool canConfirmPickupReady({
    required BorrowRequest request,
    required String borrowerId,
  }) {
    return request.borrowerId == borrowerId &&
        request.status == AppConstants.borrowStatusApproved &&
        isPaymentComplete(request);
  }

  static bool canSubmitReturn({
    required BorrowRequest request,
    required String borrowerId,
  }) {
    return request.borrowerId == borrowerId &&
        request.status == AppConstants.borrowStatusActive;
  }

  static bool isNoIssueReturnCondition(String conditionAfter) {
    return conditionAfter.trim() == AppConstants.borrowConditionAfterSame;
  }

  static String depositDecisionForReturn({
    required bool hasDeposit,
    required String conditionAfter,
  }) {
    if (!hasDeposit) return AppConstants.depositDecisionNotRequired;
    return isNoIssueReturnCondition(conditionAfter)
        ? AppConstants.depositDecisionReturnDeposit
        : AppConstants.depositDecisionPending;
  }

  static bool hasDepositReleased(BorrowRequest request) {
    return request.depositDecision ==
            AppConstants.depositDecisionReturnDeposit ||
        request.depositDecision == AppConstants.depositDecisionNotRequired;
  }

  static String generateFourDigitCode({Random? random}) {
    final generator = random ?? Random();
    return (1000 + generator.nextInt(9000)).toString();
  }
}
