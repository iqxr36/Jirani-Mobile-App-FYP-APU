import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/service_request_model.dart';
import 'package:jirani/shared/services/payment_service.dart';

void main() {
  group('Service escrow payment model', () {
    test('parses escrow state fields from Firestore data', () {
      final now = Timestamp.fromDate(DateTime(2026, 7, 5, 12));
      final request = ServiceRequestModel.fromMap('request-1', {
        'serviceId': 'service-1',
        'serviceTitle': 'Math tutoring',
        'providerId': 'provider-1',
        'providerName': 'Provider',
        'requesterId': 'requester-1',
        'requesterName': 'Requester',
        'message': 'Need help',
        'preferredDate': now,
        'preferredTime': '10:00 AM',
        'status': AppConstants.serviceRequestStatusPaidHeld,
        'paymentStatus': AppConstants.paymentStatusSucceeded,
        'paymentId': 'payment-1',
        'paymentProvider': AppConstants.paymentProviderXendit,
        'amount': 35.5,
        'currency': AppConstants.defaultPaymentCurrency,
        'providerPayoutAmount': 35.5,
        'payoutStatus': AppConstants.servicePayoutStatusNotStarted,
        'refundStatus': AppConstants.refundStatusNotStarted,
        'createdAt': now,
        'updatedAt': now,
      });

      expect(request.status, AppConstants.serviceRequestStatusPaidHeld);
      expect(request.paymentStatus, AppConstants.paymentStatusSucceeded);
      expect(request.amount, 35.5);
      expect(request.providerPayoutAmount, 35.5);
      expect(request.isPaidService, isTrue);
    });

    test('parses dispute type and reason from Firestore data', () {
      final now = Timestamp.fromDate(DateTime(2026, 7, 5, 12));
      final request = ServiceRequestModel.fromMap('request-disputed', {
        'serviceId': 'service-1',
        'serviceTitle': 'Math tutoring',
        'providerId': 'provider-1',
        'providerName': 'Provider',
        'requesterId': 'requester-1',
        'requesterName': 'Requester',
        'message': 'Need help',
        'preferredDate': now,
        'preferredTime': '10:00 AM',
        'status': AppConstants.serviceRequestStatusDisputed,
        'disputeType': AppConstants.serviceDisputeTypePoorQuality,
        'disputeReason': 'Lessons were rushed and incomplete',
        'createdAt': now,
        'updatedAt': now,
      });

      expect(request.disputeType, AppConstants.serviceDisputeTypePoorQuality);
      expect(request.disputeReason, 'Lessons were rushed and incomplete');
      expect(
        AppConstants.serviceDisputeTypeLabel(request.disputeType),
        'Poor quality or unsatisfactory work',
      );
    });

    test('converts agreed service amount to minor units', () {
      final now = Timestamp.fromDate(DateTime(2026, 7, 5, 12));
      final request = ServiceRequestModel.fromMap('request-2', {
        'serviceId': 'service-2',
        'serviceTitle': 'Cleaning',
        'providerId': 'provider-2',
        'providerName': 'Provider',
        'requesterId': 'requester-2',
        'requesterName': 'Requester',
        'message': 'Please clean kitchen',
        'preferredDate': now,
        'preferredTime': '2:00 PM',
        'status': AppConstants.serviceRequestStatusAcceptedAwaitingPayment,
        'amount': 42.75,
        'createdAt': now,
        'updatedAt': now,
      });

      expect(PaymentService.serviceAmountInMinorUnits(request), 4275);
    });
  });
}
