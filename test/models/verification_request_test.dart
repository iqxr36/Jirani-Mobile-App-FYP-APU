// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : verification_request_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Sunday,28-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/shared/models/verification_request.dart';

void main() {
  group('VerificationRequest', () {
    test('parses structured extracted fields from Firestore maps', () {
      final request = VerificationRequest.fromMap({
        'id': 'request-1',
        'userId': 'user-1',
        'fullName': 'Nur Aisyah',
        'email': 'nur@example.com',
        'phoneNumber': '+60123456789',
        'documentType': 'accessCard',
        'documentUrl': 'https://example.com/card.png',
        'communityId': 'community-1',
        'communityName': 'Vista Harmoni',
        'unitNumber': 'A-18-07',
        'notes': '',
        'status': 'submitted',
        'submittedAt': '2026-06-18T00:00:00.000',
        'extractedFields': {
          'resident_name': {
            'value': 'Nur Aisyah',
            'confidence': 0.87,
            'source': 'gemini',
          },
          'card_number': '2452718904',
        },
      });

      expect(request.extractedFields['resident_name']?.value, 'Nur Aisyah');
      expect(request.extractedFields['resident_name']?.confidence, 0.87);
      expect(request.extractedFields['resident_name']?.source, 'gemini');
      expect(request.extractedFields['card_number']?.value, '2452718904');
      expect(request.extractedFields['card_number']?.confidence, 0);
    });
  });
}
