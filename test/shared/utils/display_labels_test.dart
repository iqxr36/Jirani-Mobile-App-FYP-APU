// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : display_labels_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,09-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/utils/display_labels.dart';

void main() {
  group('lookupDisplayLabel', () {
    test('maps known service dispute types', () {
      expect(
        lookupDisplayLabel(AppConstants.serviceDisputeTypePoorQuality),
        'Poor quality or unsatisfactory work',
      );
    });

    test('maps snake_case payment statuses', () {
      expect(
        lookupDisplayLabel(AppConstants.refundStatusNotStarted),
        'Not Started',
      );
      expect(
        lookupDisplayLabel(AppConstants.manualPayoutStatusPendingManual),
        'Awaiting Manual Payout',
      );
    });

    test('formats unknown camelCase ids for display', () {
      expect(lookupDisplayLabel('someUnknownField'), 'Some Unknown Field');
      expect(lookupDisplayLabel('acceptedAwaitingPayment'), 'Awaiting Payment');
    });
  });

  group('borrowRequestStatusLabel', () {
    test('uses checkout label before payment completes', () {
      expect(
        borrowRequestStatusLabel(AppConstants.borrowStatusApproved),
        'Checkout',
      );
      expect(
        borrowRequestStatusLabel(
          AppConstants.borrowStatusApproved,
          paymentComplete: true,
        ),
        'Paid',
      );
    });
  });

  group('serviceRequestStatusLabel', () {
    test('maps paid service lifecycle statuses', () {
      expect(
        serviceRequestStatusLabel(
          AppConstants.serviceRequestStatusAcceptedAwaitingPayment,
        ),
        'Awaiting Payment',
      );
      expect(
        serviceRequestStatusLabel(AppConstants.serviceRequestStatusPaidHeld),
        'Paid',
      );
      expect(
        serviceRequestStatusLabel(AppConstants.serviceRequestStatusInProgress),
        'In Progress',
      );
    });
  });
}
