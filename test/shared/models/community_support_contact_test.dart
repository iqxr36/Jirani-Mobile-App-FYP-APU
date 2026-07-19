// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : community_support_contact_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,18-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/shared/models/community_support_contact.dart';

void main() {
  group('CommunitySupportContact', () {
    test('parses and trims Firestore data', () {
      final updatedAt = Timestamp.fromDate(DateTime(2026, 7, 18));
      final contact = CommunitySupportContact.fromMap(
        <String, dynamic>{
          'contactName': '  Amina Rahman  ',
          'email': '  support@example.com ',
          'phoneNumber': ' +60123456789 ',
          'updatedBy': ' admin-1 ',
          'updatedAt': updatedAt,
        },
        ' community-1 ',
      );

      expect(contact.communityId, 'community-1');
      expect(contact.contactName, 'Amina Rahman');
      expect(contact.email, 'support@example.com');
      expect(contact.phoneNumber, '+60123456789');
      expect(contact.updatedBy, 'admin-1');
      expect(contact.updatedAt, updatedAt);
    });

    test('supports missing legacy fields and serializes trimmed values', () {
      final contact = CommunitySupportContact.fromMap(
        const <String, dynamic>{},
        'community-1',
      );
      expect(contact.contactName, isEmpty);
      expect(contact.updatedAt, isNull);

      final map = const CommunitySupportContact(
        communityId: ' community-1 ',
        contactName: ' Amina Rahman ',
        email: ' support@example.com ',
        phoneNumber: ' +60123456789 ',
        updatedBy: ' admin-1 ',
      ).toMap();
      expect(map['communityId'], 'community-1');
      expect(map['contactName'], 'Amina Rahman');
      expect(map['email'], 'support@example.com');
      expect(map['phoneNumber'], '+60123456789');
      expect(map['updatedBy'], 'admin-1');
      expect(map['updatedAt'], isA<FieldValue>());
    });
  });
}
