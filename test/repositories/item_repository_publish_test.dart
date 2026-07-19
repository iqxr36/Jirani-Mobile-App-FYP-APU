// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : item_repository_publish_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/data/repositories/item_repository.dart';
import 'package:jirani/shared/models/app_user.dart';

void main() {
  group('ItemRepository.addItem publish order', () {
    const uid = 'resident-1';

    late FakeFirebaseFirestore firestore;
    late ItemRepository repository;

    AppUser verifiedUser({bool verified = true}) {
      final now = DateTime(2026, 6, 1);
      return AppUser(
        uid: uid,
        firstName: 'Test',
        lastName: 'Resident',
        email: 'resident@example.com',
        phoneNumber: '+60123456789',
        emailVerified: true,
        phoneVerified: true,
        role: AppConstants.roleResident,
        verificationStatus: verified
            ? AppConstants.verificationVerified
            : AppConstants.verificationPending,
        profileImageUrl: '',
        communityId: 'community-1',
        communityName: 'One South',
        unitNumber: 'A-1-1',
        reputationScore: 0,
        totalReviews: 0,
        completedBorrowings: 0,
        completedLendings: 0,
        completedServices: 0,
        termsAccepted: true,
        locationVerified: true,
        createdAt: now,
        updatedAt: now,
      );
    }

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = ItemRepository(
        auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid)),
        firestore: firestore,
      );
    });

    Future<int> itemCount() async {
      final snap = await firestore
          .collection(AppConstants.itemsCollection)
          .get();
      return snap.docs.length;
    }

    test('rejects unverified residents before creating an item document',
        () async {
      await expectLater(
        repository.addItem(
          title: 'Drill',
          description: 'Hammer drill with carrying case.',
          category: AppConstants.itemCategoryTools,
          condition: AppConstants.itemConditionGood,
          imagePaths: const [],
          hasUsageFee: false,
          hasDeposit: false,
          pickupInstructions: 'Lobby pickup',
          currentUser: verifiedUser(verified: false),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Only verified residents can list marketplace items.'),
          ),
        ),
      );

      expect(await itemCount(), 0);
    });

    test('validates listing fields before creating an item document', () async {
      await expectLater(
        repository.addItem(
          title: '',
          description: 'Hammer drill with carrying case.',
          category: AppConstants.itemCategoryTools,
          condition: AppConstants.itemConditionGood,
          imagePaths: const [],
          hasUsageFee: false,
          hasDeposit: false,
          pickupInstructions: 'Lobby pickup',
          currentUser: verifiedUser(),
        ),
        throwsA(isA<Exception>()),
      );

      expect(await itemCount(), 0);
    });

    test('requires at least one photo before upload or Firestore write', () async {
      await expectLater(
        repository.addItem(
          title: 'Drill',
          description: 'Hammer drill with carrying case.',
          category: AppConstants.itemCategoryTools,
          condition: AppConstants.itemConditionGood,
          imagePaths: const [],
          hasUsageFee: false,
          hasDeposit: false,
          pickupInstructions: 'Lobby pickup',
          currentUser: verifiedUser(),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Add at least one item photo.'),
          ),
        ),
      );

      expect(await itemCount(), 0);
    });
  });
}
