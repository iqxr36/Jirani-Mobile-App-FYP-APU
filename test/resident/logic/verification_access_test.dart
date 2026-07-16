import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/logic/verification_access.dart';
import 'package:jirani/shared/models/app_user.dart';

void main() {
  group('residentCanStartProtectedListeners', () {
    test('returns false for pending resident with location verified', () {
      final user = _resident(
        verificationStatus: AppConstants.verificationPending,
        locationVerified: true,
      );

      expect(residentCanStartProtectedListeners(user), isFalse);
      expect(residentHasFullAppAccess(user), isFalse);
    });

    test('returns false for verified resident without location verified', () {
      final user = _resident(
        verificationStatus: AppConstants.verificationVerified,
        locationVerified: false,
      );

      expect(residentCanStartProtectedListeners(user), isFalse);
      expect(residentHasFullAppAccess(user), isFalse);
    });

    test('returns true for verified resident with location verified', () {
      final user = _resident(
        verificationStatus: AppConstants.verificationVerified,
        locationVerified: true,
      );

      expect(residentCanStartProtectedListeners(user), isTrue);
      expect(residentHasFullAppAccess(user), isTrue);
    });

    test('returns false for null user', () {
      expect(residentCanStartProtectedListeners(null), isFalse);
    });
  });
}

AppUser _resident({
  required String verificationStatus,
  required bool locationVerified,
}) {
  final now = DateTime(2026, 7, 11);
  return AppUser(
    uid: 'resident-1',
    firstName: 'Test',
    lastName: 'Resident',
    email: 'test@example.com',
    phoneNumber: '+60123456789',
    emailVerified: true,
    phoneVerified: true,
    role: AppConstants.roleResident,
    verificationStatus: verificationStatus,
    profileImageUrl: '',
    communityId: 'community-1',
    communityName: 'Community',
    unitNumber: 'A-1-1',
    reputationScore: 0,
    totalReviews: 0,
    completedBorrowings: 0,
    completedLendings: 0,
    completedServices: 0,
    termsAccepted: true,
    locationVerified: locationVerified,
    createdAt: now,
    updatedAt: now,
  );
}
