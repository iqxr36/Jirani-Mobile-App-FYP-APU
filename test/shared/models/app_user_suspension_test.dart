import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';

void main() {
  group('AppUser suspension', () {
    final now = DateTime(2026, 7, 16, 12);

    test('finite suspension is active before its end time', () {
      final user = _suspendedUser(
        suspensionEndsAt: now.add(const Duration(days: 7)),
      );

      expect(user.isSuspensionActiveAt(now), isTrue);
    });

    test('finite suspension is no longer active at its end time', () {
      final user = _suspendedUser(suspensionEndsAt: now);

      expect(user.isSuspensionActiveAt(now), isFalse);
    });

    test('indefinite suspension remains active', () {
      final user = _suspendedUser();

      expect(user.isSuspensionActiveAt(now), isTrue);
    });

    test('parses and serializes the suspension end timestamp', () {
      final endsAt = now.add(const Duration(days: 3));
      final user = AppUser.fromMap({
        ..._baseMap(),
        'accountStatus': AppConstants.accountStatusSuspended,
        'suspensionEndsAt': Timestamp.fromDate(endsAt),
      });

      expect(user.suspensionEndsAt, endsAt);
      expect((user.toMap()['suspensionEndsAt'] as Timestamp).toDate(), endsAt);
    });
  });
}

AppUser _suspendedUser({DateTime? suspensionEndsAt}) {
  return AppUser.fromMap({
    ..._baseMap(),
    'accountStatus': AppConstants.accountStatusSuspended,
    if (suspensionEndsAt != null)
      'suspensionEndsAt': Timestamp.fromDate(suspensionEndsAt),
  });
}

Map<String, dynamic> _baseMap() {
  final createdAt = Timestamp.fromDate(DateTime(2026, 1, 1));
  return {
    'uid': 'resident-1',
    'firstName': 'Test',
    'lastName': 'Resident',
    'email': 'resident@example.com',
    'phoneNumber': '+60123456789',
    'role': AppConstants.roleResident,
    'verificationStatus': AppConstants.verificationVerified,
    'communityId': 'community-1',
    'communityName': 'One South',
    'termsAccepted': true,
    'locationVerified': true,
    'createdAt': createdAt,
    'updatedAt': createdAt,
  };
}
