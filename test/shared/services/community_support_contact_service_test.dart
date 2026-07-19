// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : community_support_contact_service_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,18-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/community_support_contact.dart';
import 'package:jirani/shared/services/community_support_contact_service.dart';

void main() {
  group('CommunitySupportContactService', () {
    test('saves and fetches the community contact', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CommunitySupportContactService(firestore: firestore);

      await service.saveForCommunity(
        const CommunitySupportContact(
          communityId: 'community-1',
          contactName: 'Amina Rahman',
          email: 'support@example.com',
          phoneNumber: '+60123456789',
          updatedBy: 'admin-1',
        ),
      );

      final contact = await service.fetchForCommunity('community-1');
      expect(contact?.contactName, 'Amina Rahman');
      expect(contact?.email, 'support@example.com');
      final snapshot = await firestore
          .collection(AppConstants.communitySupportContactsCollection)
          .doc('community-1')
          .get();
      expect(snapshot.data()?['updatedAt'], isNotNull);
    });

    test('empty community lookup returns null and empty save is rejected', () async {
      final service = CommunitySupportContactService(
        firestore: FakeFirebaseFirestore(),
      );

      expect(await service.fetchForCommunity('  '), isNull);
      expect(
        () => service.saveForCommunity(
          const CommunitySupportContact(
            communityId: '',
            contactName: 'Amina Rahman',
            email: 'support@example.com',
            phoneNumber: '+60123456789',
            updatedBy: 'admin-1',
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
