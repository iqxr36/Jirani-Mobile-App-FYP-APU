// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_service_reports_test.dart (Dart source file)
// Description     : Regression tests for marketplace admin deposit dispute decisions.
// First Written on: Wednesday,22-July-2026
// Last Edited on  : Wednesday,22-July-2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/admin/logic/marketplace_dispute_resolution.dart';
import 'package:jirani/admin/services/admin_service.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/borrow_request.dart';

void main() {
  const requestId = 'request-1';
  const reportId = 'report-1';
  const ownerId = 'owner-1';
  const borrowerId = 'borrower-1';
  const itemId = 'item-1';

  Map<String, dynamic> disputedRequest({
    String conditionAfter = AppConstants.borrowConditionAfterMinor,
    double? minorDeductionAmount = 100,
    String paymentProvider = AppConstants.paymentProviderXendit,
  }) {
    return {
      'itemId': itemId,
      'itemTitle': 'Pressure washer',
      'ownerId': ownerId,
      'ownerName': 'Lender',
      'borrowerId': borrowerId,
      'borrowerName': 'Borrower',
      'status': AppConstants.borrowStatusDisputed,
      'paymentStatus': AppConstants.paymentStatusCompleted,
      'paymentProvider': paymentProvider,
      'hasDeposit': true,
      'depositAmount': 500.0,
      'itemConditionAfter': conditionAfter,
      'minorDeductionAmount': minorDeductionAmount,
      'minorIssueBorrowerDecision': AppConstants.minorIssueDecisionDeclined,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
  }

  group('AdminService.resolveMarketplaceDispute', () {
    late FakeFirebaseFirestore firestore;
    late _RecordingAdminService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = _RecordingAdminService(firestore);
    });

    test('uses requested partial deduction for managed minor damage', () async {
      await firestore
          .collection(AppConstants.borrowRequestsCollection)
          .doc(requestId)
          .set(disputedRequest());

      await service.resolveMarketplaceDispute(
        reportId: reportId,
        borrowRequestId: requestId,
        adminUid: 'admin-1',
        resolveForBorrower: false,
        reason: 'Minor repair approved',
      );

      expect(
        service.recordedDecision,
        AppConstants.depositResolutionPartialDeduction,
      );
      expect(service.recordedDeductionAmount, 100);
      expect(service.recordedReportId, reportId);
    });

    test('keeps full deduction for managed major damage', () async {
      await firestore
          .collection(AppConstants.borrowRequestsCollection)
          .doc(requestId)
          .set(
            disputedRequest(
              conditionAfter: AppConstants.borrowConditionAfterMajor,
              minorDeductionAmount: null,
            ),
          );

      await service.resolveMarketplaceDispute(
        reportId: reportId,
        borrowRequestId: requestId,
        adminUid: 'admin-1',
        resolveForBorrower: false,
        reason: 'Major damage confirmed',
      );

      expect(
        service.recordedDecision,
        AppConstants.depositResolutionFullDeduction,
      );
      expect(service.recordedDeductionAmount, 500);
    });

    test(
      'keeps full refund when managed dispute resolves for borrower',
      () async {
        await firestore
            .collection(AppConstants.borrowRequestsCollection)
            .doc(requestId)
            .set(disputedRequest());

        await service.resolveMarketplaceDispute(
          reportId: reportId,
          borrowRequestId: requestId,
          adminUid: 'admin-1',
          resolveForBorrower: true,
          reason: 'Evidence supports borrower',
        );

        expect(
          service.recordedDecision,
          AppConstants.depositResolutionFullRefund,
        );
        expect(service.recordedDeductionAmount, 0);
      },
    );

    test(
      'rejects invalid managed minor deduction without settlement',
      () async {
        await firestore
            .collection(AppConstants.borrowRequestsCollection)
            .doc(requestId)
            .set(disputedRequest(minorDeductionAmount: 500));

        await expectLater(
          service.resolveMarketplaceDispute(
            reportId: reportId,
            borrowRequestId: requestId,
            adminUid: 'admin-1',
            resolveForBorrower: false,
            reason: 'Approve lender claim',
          ),
          throwsA(isA<MarketplaceDisputeResolutionException>()),
        );
        expect(service.recordedDecision, isNull);
      },
    );

    test('records partial decision for non-managed minor damage', () async {
      await firestore
          .collection(AppConstants.borrowRequestsCollection)
          .doc(requestId)
          .set(disputedRequest(paymentProvider: 'legacy'));
      await firestore.collection(AppConstants.itemsCollection).doc(itemId).set({
        'status': AppConstants.itemStatusBorrowed,
      });
      await firestore.collection(AppConstants.usersCollection).doc(ownerId).set(
        {'completedLendings': 0},
      );
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(borrowerId)
          .set({'completedBorrowings': 0});
      await firestore
          .collection(AppConstants.reportsCollection)
          .doc(reportId)
          .set({'status': AppConstants.reportStatusOpen});

      await service.resolveMarketplaceDispute(
        reportId: reportId,
        borrowRequestId: requestId,
        adminUid: 'admin-1',
        resolveForBorrower: false,
        reason: 'Minor repair approved',
      );

      final request = await firestore
          .collection(AppConstants.borrowRequestsCollection)
          .doc(requestId)
          .get();
      expect(
        request.data()?['depositDecision'],
        AppConstants.depositDecisionPartialDeduction,
      );
      expect(request.data()?['damageDeductionAmount'], 100);
      expect(
        request.data()?['damageDecision'],
        AppConstants.damageDecisionAdminPartialDeduction,
      );
      expect(request.data()?['status'], AppConstants.borrowStatusCompleted);

      final report = await firestore
          .collection(AppConstants.reportsCollection)
          .doc(reportId)
          .get();
      expect(report.data()?['status'], AppConstants.reportStatusResolved);
    });
  });

  test(
    'minor resolution preview calculates lender award and borrower refund',
    () {
      final request = _borrowRequestFrom(disputedRequest());

      final resolution = marketplaceDisputeDepositResolutionFor(
        request: request,
        resolveForBorrower: false,
      );

      expect(resolution.damageDeductionAmount, 100);
      expect(resolution.borrowerRefundAmount, 400);
      expect(resolution.isMinorDamageDeduction, isTrue);
    },
  );
}

class _RecordingAdminService extends AdminService {
  _RecordingAdminService(FirebaseFirestore firestore)
    : super(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'admin-1'),
        ),
        firestore: firestore,
      );

  String? recordedDecision;
  double? recordedDeductionAmount;
  String? recordedReportId;

  @override
  Future<void> resolveMarketplaceDeposit({
    required String borrowRequestId,
    required String decision,
    required double damageDeductionAmount,
    required String reason,
    String reportId = '',
  }) async {
    recordedDecision = decision;
    recordedDeductionAmount = damageDeductionAmount;
    recordedReportId = reportId;
  }
}

BorrowRequest _borrowRequestFrom(Map<String, dynamic> data) {
  // Kept local so the helper test uses the same Firestore parsing path as the
  // admin service.
  return BorrowRequest.fromMap('request-preview', data);
}
