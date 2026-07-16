import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/borrow_request.dart';
import 'package:jirani/shared/services/review_service.dart';

void main() {
  group('ReviewService.reviewDocId', () {
    test('combines borrow request id and reviewer id', () {
      expect(
        ReviewService.reviewDocId('borrow/1', 'user-a'),
        'borrow_1_user-a',
      );
    });
  });

  group('ReviewService.createReview', () {
    const borrowId = 'borrow-1';
    const borrowerId = 'borrower-1';
    const ownerId = 'owner-1';
    const itemId = 'item-1';

    late FakeFirebaseFirestore firestore;
    late ReviewService service;

    Future<void> seedCompletedBorrow() async {
      final now = Timestamp.fromDate(DateTime(2026, 6, 1, 12));
      await firestore
          .collection(AppConstants.borrowRequestsCollection)
          .doc(borrowId)
          .set({
            'id': borrowId,
            'itemId': itemId,
            'itemTitle': 'Drill',
            'itemImageUrl': '',
            'ownerId': ownerId,
            'ownerName': 'Owner One',
            'ownerEmail': 'owner@example.com',
            'borrowerId': borrowerId,
            'borrowerName': 'Borrower One',
            'borrowerEmail': 'borrower@example.com',
            'borrowerPhoneNumber': '',
            'borrowerVerified': true,
            'borrowerReputationScore': 0,
            'requestedStartDate': now,
            'expectedReturnDate': now,
            'pickupTime': '10:00',
            'message': '',
            'status': AppConstants.borrowStatusCompleted,
            'paymentStatus': AppConstants.paymentStatusCompleted,
            'paymentCompletedAt': now,
            'paymentProvider': AppConstants.paymentProviderManualV1,
            'chatId': '',
            'handoverCode': '',
            'returnCode': '',
            'usageFeeAmount': null,
            'depositAmount': null,
            'hasUsageFee': false,
            'hasDeposit': false,
            'createdAt': now,
            'updatedAt': now,
            'approvedAt': now,
            'rejectedAt': null,
            'rejectionReason': '',
            'pickupConfirmedAt': null,
            'handoverConfirmedAt': null,
            'returnSubmittedAt': null,
            'returnConfirmedAt': null,
            'completedAt': now,
            'pickupProofImageUrl': null,
            'handoverProofImageUrl': null,
            'returnProofImageUrl': null,
            'itemConditionBefore': null,
            'itemConditionAfter': null,
            'returnNotes': '',
            'ownerReturnNotes': '',
            'depositDecision': AppConstants.depositDecisionNotRequired,
            'depositDecisionReason': '',
            'depositDecidedAt': null,
          });
      await firestore
          .collection(AppConstants.publicProfilesCollection)
          .doc(ownerId)
          .set({'displayName': 'Owner One', 'updatedAt': now});
    }

    BorrowRequest completedRequest() {
      return _completedBorrowRequest(
        id: borrowId,
        borrowerId: borrowerId,
        ownerId: ownerId,
        itemId: itemId,
      );
    }

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = ReviewService(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: borrowerId),
        ),
        firestore: firestore,
        useCallableSubmission: false,
      );
    });

    test('rejects reviews for non-completed borrow requests', () async {
      final pending = completedRequest().copyWith(
        status: AppConstants.borrowStatusPending,
      );

      await expectLater(
        service.createReview(
          borrowRequest: pending,
          reviewerId: borrowerId,
          reviewerName: 'Borrower One',
          role: AppConstants.reviewRoleBorrowerToOwner,
          rating: 5,
          comment: 'Great lender',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Only completed borrow requests can be reviewed.'),
          ),
        ),
      );
    });

    test('rejects invalid review roles and mismatched reviewer', () async {
      await seedCompletedBorrow();
      final request = completedRequest();
      final ownerService = ReviewService(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: ownerId),
        ),
        firestore: firestore,
        useCallableSubmission: false,
      );

      await expectLater(
        ownerService.createReview(
          borrowRequest: request,
          reviewerId: ownerId,
          reviewerName: 'Owner One',
          role: AppConstants.reviewRoleBorrowerToOwner,
          rating: 5,
          comment: 'Great lender',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Only the borrower can submit this review.'),
          ),
        ),
      );
    });

    test(
      'creates hidden review and flags borrow request during blind period',
      () async {
        await seedCompletedBorrow();
        final request = completedRequest();

        await service.createReview(
          borrowRequest: request,
          reviewerId: borrowerId,
          reviewerName: 'Borrower One',
          role: AppConstants.reviewRoleBorrowerToOwner,
          rating: 5,
          comment: 'Smooth handover',
        );

        final reviewId = ReviewService.reviewDocId(borrowId, borrowerId);
        final reviewSnap = await firestore
            .collection(AppConstants.reviewsCollection)
            .doc(reviewId)
            .get();
        final borrowSnap = await firestore
            .collection(AppConstants.borrowRequestsCollection)
            .doc(borrowId)
            .get();

        expect(reviewSnap.exists, isTrue);
        expect(reviewSnap.data()?['visible'], isFalse);
        expect(reviewSnap.data()?['status'], AppConstants.reviewStatusHidden);
        expect(reviewSnap.data()?['revieweeId'], ownerId);
        expect(reviewSnap.data()?['publishAfter'], isNotNull);

        expect(borrowSnap.data()?['borrowerReviewSubmitted'], isTrue);
        expect(borrowSnap.data()?['reviewGraceEndsAt'], isNotNull);
      },
    );

    test('prevents duplicate reviews for the same borrow request', () async {
      await seedCompletedBorrow();
      final request = completedRequest();

      await service.createReview(
        borrowRequest: request,
        reviewerId: borrowerId,
        reviewerName: 'Borrower One',
        role: AppConstants.reviewRoleBorrowerToOwner,
        rating: 4,
        comment: 'Good',
      );

      await expectLater(
        service.createReview(
          borrowRequest: request,
          reviewerId: borrowerId,
          reviewerName: 'Borrower One',
          role: AppConstants.reviewRoleBorrowerToOwner,
          rating: 3,
          comment: 'Retry',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('You already submitted a review'),
          ),
        ),
      );
    });
  });
}

BorrowRequest _completedBorrowRequest({
  required String id,
  required String borrowerId,
  required String ownerId,
  required String itemId,
}) {
  final now = DateTime(2026, 6, 1, 12);
  return BorrowRequest(
    id: id,
    itemId: itemId,
    itemTitle: 'Drill',
    itemImageUrl: '',
    ownerId: ownerId,
    ownerName: 'Owner One',
    ownerEmail: 'owner@example.com',
    borrowerId: borrowerId,
    borrowerName: 'Borrower One',
    borrowerEmail: 'borrower@example.com',
    borrowerPhoneNumber: '',
    borrowerVerified: true,
    borrowerReputationScore: 0,
    requestedStartDate: now,
    expectedReturnDate: now,
    pickupTime: '10:00',
    message: '',
    status: AppConstants.borrowStatusCompleted,
    paymentStatus: AppConstants.paymentStatusCompleted,
    paymentCompletedAt: now,
    paymentProvider: AppConstants.paymentProviderManualV1,
    chatId: '',
    handoverCode: '',
    returnCode: '',
    hasUsageFee: false,
    usageFeeAmount: null,
    hasDeposit: false,
    depositAmount: null,
    createdAt: now,
    updatedAt: now,
    approvedAt: now,
    rejectedAt: null,
    rejectionReason: '',
    pickupConfirmedAt: null,
    handoverConfirmedAt: null,
    returnSubmittedAt: null,
    returnConfirmedAt: null,
    completedAt: now,
    pickupProofImageUrl: '',
    handoverProofImageUrl: '',
    returnProofImageUrl: '',
    itemConditionBefore: '',
    itemConditionAfter: '',
    returnNotes: '',
    ownerReturnNotes: '',
    depositDecision: AppConstants.depositDecisionNotRequired,
    depositDecisionReason: '',
    depositDecidedAt: null,
  );
}
