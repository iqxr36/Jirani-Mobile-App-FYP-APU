import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/public_resident_profile.dart';

void main() {
  group('service profile counters', () {
    test('AppUser parses completed service counters from Firestore map', () {
      final user = AppUser.fromMap({
        'uid': 'user-1',
        'firstName': 'Aisha',
        'lastName': 'Rahman',
        'email': 'aisha@example.com',
        'phoneNumber': '',
        'emailVerified': true,
        'phoneVerified': true,
        'role': 'resident',
        'verificationStatus': 'verified',
        'profileImageUrl': '',
        'communityId': 'community-1',
        'communityName': 'Demo',
        'unitNumber': 'A-1',
        'reputationScore': 4.5,
        'totalReviews': 2,
        'completedBorrowings': 1,
        'completedLendings': 0,
        'completedServices': 3,
        'completedServicesProvided': 2,
        'completedServicesRequested': 1,
      });

      expect(user.completedServices, 3);
      expect(user.completedServicesProvided, 2);
      expect(user.completedServicesRequested, 1);
    });

    test('PublicResidentProfile parses completed service counters', () {
      final profile = PublicResidentProfile.fromMap({
        'uid': 'user-1',
        'firstName': 'Aisha',
        'lastName': 'Rahman',
        'profileImageUrl': '',
        'communityId': 'community-1',
        'communityName': 'Demo',
        'role': 'resident',
        'verificationStatus': 'verified',
        'reputationScore': 4.5,
        'totalReviews': 2,
        'communityTrustScore': 4.5,
        'trustedResident': false,
        'completedBorrowings': 1,
        'completedLendings': 0,
        'completedServices': 3,
        'completedServicesProvided': 2,
        'completedServicesRequested': 1,
        'updatedAt': DateTime(2026, 7, 9),
      });

      expect(profile.completedServicesProvided, 2);
      expect(profile.completedServicesRequested, 1);
    });
  });
}
