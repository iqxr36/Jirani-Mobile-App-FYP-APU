// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : community_change_test.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,18-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/community_change.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/community_model.dart';

void main() {
  group('community change utils', () {
    final communityA = CommunityModel(
      communityId: 'community-a',
      name: 'Community A',
      centerLocation: const GeoPoint(3.0, 101.0),
      radiusInMeters: 500,
      isActive: true,
      city: 'City A',
    );
    final communityB = communityA.copyWith(
      communityId: 'community-b',
      name: 'Community B',
      city: 'City B',
    );

    test('returns false when user is null', () {
      expect(
        isChangingSavedCommunity(user: null, nextCommunity: communityB),
        isFalse,
      );
    });

    test('returns false when user has no saved community', () {
      final user = _user(communityId: '', communityName: '');

      expect(
        isChangingSavedCommunity(user: user, nextCommunity: communityB),
        isFalse,
      );
    });

    test('returns false when selecting the same community by id', () {
      final user = _user(
        communityId: communityA.communityId,
        communityName: communityA.name,
      );

      expect(
        isChangingSavedCommunity(user: user, nextCommunity: communityA),
        isFalse,
      );
    });

    test('returns true when community id changes', () {
      final user = _user(
        communityId: communityA.communityId,
        communityName: communityA.name,
      );

      expect(
        isChangingSavedCommunity(user: user, nextCommunity: communityB),
        isTrue,
      );
    });

    test('falls back to community name when ids are missing', () {
      final user = _user(communityId: '', communityName: 'Community A');

      expect(
        isChangingSavedCommunity(user: user, nextCommunity: communityB),
        isTrue,
      );
    });

    test('needsCommunityChangeWarning mirrors saved community change', () {
      final verifiedUser = _user(
        communityId: communityA.communityId,
        communityName: communityA.name,
        verificationStatus: AppConstants.verificationVerified,
      );
      final pendingUser = verifiedUser.copyWith(
        verificationStatus: AppConstants.verificationPending,
      );

      expect(
        needsCommunityChangeWarning(
          user: verifiedUser,
          nextCommunity: communityB,
        ),
        isTrue,
      );
      expect(
        needsCommunityChangeWarning(user: pendingUser, nextCommunity: communityB),
        isTrue,
      );
      expect(
        needsCommunityChangeWarning(
          user: pendingUser,
          nextCommunity: communityA,
        ),
        isFalse,
      );
    });
  });
}

AppUser _user({
  required String communityId,
  required String communityName,
  String verificationStatus = AppConstants.verificationPending,
}) {
  final now = DateTime(2026, 6, 18);
  return AppUser(
    uid: 'user-1',
    firstName: 'Test',
    lastName: 'Resident',
    email: 'test@example.com',
    phoneNumber: '+60123456789',
    emailVerified: true,
    phoneVerified: true,
    role: AppConstants.roleResident,
    verificationStatus: verificationStatus,
    profileImageUrl: '',
    communityId: communityId,
    communityName: communityName,
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

extension on CommunityModel {
  CommunityModel copyWith({
    String? communityId,
    String? name,
    GeoPoint? centerLocation,
    double? radiusInMeters,
    bool? isActive,
    String? city,
  }) {
    return CommunityModel(
      communityId: communityId ?? this.communityId,
      name: name ?? this.name,
      centerLocation: centerLocation ?? this.centerLocation,
      radiusInMeters: radiusInMeters ?? this.radiusInMeters,
      isActive: isActive ?? this.isActive,
      city: city ?? this.city,
    );
  }
}
