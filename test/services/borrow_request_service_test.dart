import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/services/borrow_request_service.dart';

void main() {
  group('BorrowRequestService.approveBorrowRequest', () {
    const ownerId = 'owner-1';
    const borrowerA = 'borrower-a';
    const borrowerB = 'borrower-b';
    const itemId = 'item-1';

    late FakeFirebaseFirestore firestore;
    late BorrowRequestService service;

    Future<void> seedItem() async {
      await firestore.collection(AppConstants.itemsCollection).doc(itemId).set({
        'ownerId': ownerId,
        'title': 'Drill',
        'status': AppConstants.itemStatusAvailable,
        'updatedAt': Timestamp.now(),
      });
    }

    Future<void> seedPendingRequest({
      required String requestId,
      required String borrowerId,
    }) async {
      final now = Timestamp.now();
      await firestore
          .collection(AppConstants.borrowRequestsCollection)
          .doc(requestId)
          .set({
        'id': requestId,
        'itemId': itemId,
        'itemTitle': 'Drill',
        'itemImageUrl': '',
        'ownerId': ownerId,
        'ownerName': 'Owner One',
        'ownerEmail': 'owner@example.com',
        'borrowerId': borrowerId,
        'borrowerName': 'Borrower',
        'borrowerEmail': '$borrowerId@example.com',
        'borrowerPhoneNumber': '',
        'borrowerVerified': true,
        'borrowerReputationScore': 0,
        'requestedStartDate': now,
        'expectedReturnDate': now,
        'pickupTime': '10:00',
        'message': 'Need this item',
        'status': AppConstants.borrowStatusPending,
        'paymentStatus': AppConstants.paymentStatusPending,
        'paymentCompletedAt': null,
        'paymentProvider': '',
        'chatId': '',
        'handoverCode': '',
        'returnCode': '',
        'usageFeeAmount': null,
        'depositAmount': null,
        'hasUsageFee': false,
        'hasDeposit': false,
        'createdAt': now,
        'updatedAt': now,
        'approvedAt': null,
        'rejectedAt': null,
        'rejectionReason': '',
        'pickupConfirmedAt': null,
        'handoverConfirmedAt': null,
        'returnSubmittedAt': null,
        'returnConfirmedAt': null,
        'completedAt': null,
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
    }

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = BorrowRequestService(
        auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: ownerId)),
        firestore: firestore,
      );
    });

    test('approves selected request, marks item unavailable, rejects siblings',
        () async {
      await seedItem();
      await seedPendingRequest(requestId: 'req-a', borrowerId: borrowerA);
      await seedPendingRequest(requestId: 'req-b', borrowerId: borrowerB);

      await service.approveBorrowRequest(
        requestId: 'req-a',
        ownerId: ownerId,
      );

      final approved = await firestore
          .collection(AppConstants.borrowRequestsCollection)
          .doc('req-a')
          .get();
      final rejected = await firestore
          .collection(AppConstants.borrowRequestsCollection)
          .doc('req-b')
          .get();
      final item = await firestore
          .collection(AppConstants.itemsCollection)
          .doc(itemId)
          .get();

      expect(approved.data()?['status'], AppConstants.borrowStatusApproved);
      expect(rejected.data()?['status'], AppConstants.borrowStatusRejected);
      expect(
        rejected.data()?['rejectionReason'],
        'Item was approved for another borrower.',
      );
      expect(item.data()?['status'], AppConstants.itemStatusUnavailable);
    });

    test('approves when only one pending request exists', () async {
      await seedItem();
      await seedPendingRequest(requestId: 'req-a', borrowerId: borrowerA);

      await service.approveBorrowRequest(
        requestId: 'req-a',
        ownerId: ownerId,
      );

      final approved = await firestore
          .collection(AppConstants.borrowRequestsCollection)
          .doc('req-a')
          .get();
      expect(approved.data()?['status'], AppConstants.borrowStatusApproved);
    });

    test('uses owner-scoped query for competing pending requests', () async {
      await seedItem();
      await seedPendingRequest(requestId: 'req-a', borrowerId: borrowerA);

      final scoped = await firestore
          .collection(AppConstants.borrowRequestsCollection)
          .where('ownerId', isEqualTo: ownerId)
          .where('itemId', isEqualTo: itemId)
          .where('status', isEqualTo: AppConstants.borrowStatusPending)
          .get();

      expect(scoped.docs, hasLength(1));
      expect(scoped.docs.single.id, 'req-a');
    });

    test('throws when caller is not the owner', () async {
      await seedItem();
      await seedPendingRequest(requestId: 'req-a', borrowerId: borrowerA);

      final borrowerService = BorrowRequestService(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: borrowerA),
        ),
        firestore: firestore,
      );

      expect(
        () => borrowerService.approveBorrowRequest(
          requestId: 'req-a',
          ownerId: ownerId,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Only the item owner can approve this request.'),
          ),
        ),
      );
    });

    test('throws when request is not pending', () async {
      await seedItem();
      await seedPendingRequest(requestId: 'req-a', borrowerId: borrowerA);
      await firestore
          .collection(AppConstants.borrowRequestsCollection)
          .doc('req-a')
          .update({'status': AppConstants.borrowStatusApproved});

      expect(
        () => service.approveBorrowRequest(
          requestId: 'req-a',
          ownerId: ownerId,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Only pending requests can be approved.'),
          ),
        ),
      );
    });
  });
}
