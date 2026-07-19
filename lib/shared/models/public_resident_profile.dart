// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : public_resident_profile.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/app_user.dart';

/// Community-visible resident profile. Excludes private fields such as email,
/// phone number, unit number, and moderation flags.
class PublicResidentProfile {
  const PublicResidentProfile({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.profileImageUrl,
    required this.communityId,
    required this.communityName,
    required this.role,
    required this.verificationStatus,
    this.accountStatus = AppConstants.accountStatusActive,
    required this.reputationScore,
    required this.totalReviews,
    required this.communityTrustScore,
    required this.trustedResident,
    required this.completedBorrowings,
    required this.completedLendings,
    required this.completedServices,
    this.completedServicesProvided = 0,
    this.completedServicesRequested = 0,
    required this.updatedAt,
  });

  final String uid;
  final String firstName;
  final String lastName;
  final String profileImageUrl;
  final String communityId;
  final String communityName;
  final String role;
  final String verificationStatus;
  final String accountStatus;
  final double reputationScore;
  final int totalReviews;
  final double communityTrustScore;
  final bool trustedResident;
  final int completedBorrowings;
  final int completedLendings;
  final int completedServices;
  final int completedServicesProvided;
  final int completedServicesRequested;
  final DateTime updatedAt;

  /// Public profile feature: combines public first/last name for cards and profile headers.
  String get fullName => '$firstName $lastName'.trim();

  /// Public profile feature: hides inactive/unverified residents from trusted public surfaces.
  bool get isVerifiedResident =>
      verificationStatus == AppConstants.verificationVerified &&
      accountStatus == AppConstants.accountStatusActive;

  bool get isResident => role == AppConstants.roleResident;

  /// Public profile DB model: converts publicProfiles/{uid} data into the safe public resident model.
  factory PublicResidentProfile.fromMap(Map<String, dynamic> map) {
    final rawStatus = (map['verificationStatus'] as String?) ?? '';
    final normalizedStatus = rawStatus == 'approved'
        ? AppConstants.verificationVerified
        : rawStatus;
    final names = _parseNames(map);

    return PublicResidentProfile(
      uid: (map['uid'] as String?) ?? '',
      firstName: names.$1,
      lastName: names.$2,
      profileImageUrl: (map['profileImageUrl'] as String?) ?? '',
      communityId: (map['communityId'] as String?) ?? '',
      communityName: (map['communityName'] as String?) ?? '',
      role: (map['role'] as String?) ?? AppConstants.roleResident,
      verificationStatus: normalizedStatus,
      accountStatus:
          (map['accountStatus'] as String?) ?? AppConstants.accountStatusActive,
      reputationScore: _parseDouble(map['reputationScore']),
      totalReviews: _parseInt(map['totalReviews']),
      communityTrustScore: _parseDouble(
        map['communityTrustScore'] ?? map['reputationScore'],
      ),
      trustedResident: map['trustedResident'] as bool? ?? false,
      completedBorrowings: _parseInt(map['completedBorrowings']),
      completedLendings: _parseInt(map['completedLendings']),
      completedServices: _parseInt(map['completedServices']),
      completedServicesProvided: _parseInt(map['completedServicesProvided']),
      completedServicesRequested: _parseInt(map['completedServicesRequested']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  /// Minimal [AppUser] for legacy UI that still expects the full model type.
  AppUser toNeighborListUser() {
    return AppUser(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      email: '',
      phoneNumber: '',
      emailVerified: false,
      phoneVerified: false,
      role: role,
      verificationStatus: verificationStatus,
      accountStatus: accountStatus,
      profileImageUrl: profileImageUrl,
      communityId: communityId,
      communityName: communityName,
      unitNumber: '',
      reputationScore: reputationScore,
      totalReviews: totalReviews,
      communityTrustScore: communityTrustScore,
      trustedResident: trustedResident,
      completedBorrowings: completedBorrowings,
      completedLendings: completedLendings,
      completedServices: completedServices,
      completedServicesProvided: completedServicesProvided,
      completedServicesRequested: completedServicesRequested,
      termsAccepted: false,
      locationVerified: false,
      createdAt: updatedAt,
      updatedAt: updatedAt,
    );
  }

  /// Public profile DB model: supports both public first/last name fields and legacy fullName data.
  static (String, String) _parseNames(Map<String, dynamic> map) {
    final firstName = (map['firstName'] as String?)?.trim() ?? '';
    final lastName = (map['lastName'] as String?)?.trim() ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return (firstName, lastName);
    }

    final legacyFullName = ((map['fullName'] as String?) ?? '').trim();
    if (legacyFullName.isEmpty) return ('', '');

    final parts = legacyFullName.split(RegExp(r'\s+'));
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.skip(1).join(' '));
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
