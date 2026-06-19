import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/marketplace_borrow_flow.dart';
import 'package:jirani/shared/models/borrow_request.dart';

void main() {
  group('MarketplaceBorrowFlow', () {
    test('calculates inclusive daily duration and daily fee', () {
      final start = DateTime(2026, 5, 10);
      final end = DateTime(2026, 5, 12);

      expect(MarketplaceBorrowFlow.dailyDurationDays(start, end), 3);
      expect(
        MarketplaceBorrowFlow.dailyUsageFee(
          dailyFee: 25,
          start: start,
          end: end,
        ),
        75,
      );
    });

    test('total due includes fee and deposit without negative amounts', () {
      expect(MarketplaceBorrowFlow.totalDue(usageFee: 75, deposit: 50), 125);
      expect(MarketplaceBorrowFlow.totalDue(usageFee: -20, deposit: 50), 50);
    });

    test(
      'manual payment is available only for approved unpaid borrower request',
      () {
        final request = _request(
          status: AppConstants.borrowStatusApproved,
          paymentStatus: AppConstants.paymentStatusPending,
        );

        expect(
          MarketplaceBorrowFlow.canCompleteManualPayment(
            request: request,
            borrowerId: 'borrower-1',
          ),
          isTrue,
        );
        expect(
          MarketplaceBorrowFlow.canCompleteManualPayment(
            request: request,
            borrowerId: 'other-user',
          ),
          isFalse,
        );
        expect(
          MarketplaceBorrowFlow.canCompleteManualPayment(
            request: request.copyWith(
              paymentStatus: AppConstants.paymentStatusCompleted,
            ),
            borrowerId: 'borrower-1',
          ),
          isFalse,
        );
      },
    );

    test('deposit is released only for same-condition returns', () {
      expect(
        MarketplaceBorrowFlow.depositDecisionForReturn(
          hasDeposit: true,
          conditionAfter: AppConstants.borrowConditionAfterSame,
        ),
        AppConstants.depositDecisionReturnDeposit,
      );
      expect(
        MarketplaceBorrowFlow.depositDecisionForReturn(
          hasDeposit: true,
          conditionAfter: AppConstants.borrowConditionAfterMinor,
        ),
        AppConstants.depositDecisionPending,
      );
      expect(
        MarketplaceBorrowFlow.depositDecisionForReturn(
          hasDeposit: false,
          conditionAfter: AppConstants.borrowConditionAfterSame,
        ),
        AppConstants.depositDecisionNotRequired,
      );
    });

    test('generates a four digit handover code', () {
      final code = MarketplaceBorrowFlow.generateFourDigitCode(
        random: Random(42),
      );

      expect(code, matches(RegExp(r'^\d{4}$')));
      expect(int.parse(code), inInclusiveRange(1000, 9999));
    });
  });
}

BorrowRequest _request({
  required String status,
  required String paymentStatus,
}) {
  final now = DateTime(2026, 6, 18);
  return BorrowRequest(
    id: 'request-1',
    itemId: 'item-1',
    itemTitle: 'Hammer Drill',
    itemImageUrl: '',
    ownerId: 'owner-1',
    ownerName: 'Owner One',
    ownerEmail: 'owner@example.com',
    borrowerId: 'borrower-1',
    borrowerName: 'Borrower One',
    borrowerEmail: 'borrower@example.com',
    borrowerPhoneNumber: '+60123456789',
    borrowerVerified: true,
    borrowerReputationScore: 4.8,
    requestedStartDate: DateTime(2026, 5, 10),
    expectedReturnDate: DateTime(2026, 5, 12),
    pickupTime: 'Daily rental',
    message: '',
    status: status,
    paymentStatus: paymentStatus,
    paymentCompletedAt: null,
    paymentProvider: '',
    chatId: '',
    handoverCode: '',
    returnCode: '',
    hasUsageFee: true,
    usageFeeAmount: 75,
    hasDeposit: true,
    depositAmount: 50,
    createdAt: now,
    updatedAt: now,
    approvedAt: null,
    rejectedAt: null,
    rejectionReason: '',
    pickupConfirmedAt: null,
    handoverConfirmedAt: null,
    returnSubmittedAt: null,
    returnConfirmedAt: null,
    completedAt: null,
    pickupProofImageUrl: '',
    handoverProofImageUrl: '',
    returnProofImageUrl: '',
    itemConditionBefore: '',
    itemConditionAfter: '',
    returnNotes: '',
    ownerReturnNotes: '',
    depositDecision: AppConstants.depositDecisionPending,
    depositDecisionReason: '',
    depositDecidedAt: null,
  );
}
