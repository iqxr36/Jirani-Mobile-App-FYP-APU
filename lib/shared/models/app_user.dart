// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : app_user.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,13-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jirani/core/constants/app_constants.dart';

/// Auth/profile DB model: represents users/{uid}, including resident profile, admin role, verification, trust, and geofence fields.
class AppUser {
  const AppUser({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.emailVerified,
    this.pendingEmail = '',
    required this.phoneVerified,
    required this.role,
    required this.verificationStatus,
    required this.profileImageUrl,
    required this.communityId,
    required this.communityName,
    required this.unitNumber,
    required this.reputationScore,
    required this.totalReviews,
    this.communityTrustScore = 0,
    this.trustedResident = false,
    this.accountFlagged = false,
    this.trustFlagReason = '',
    this.accountStatus = AppConstants.accountStatusActive,
    this.payoutAccountStatus = AppConstants.payoutAccountStatusMissing,
    this.xenditPayoutChannel = '',
    this.payoutAccountName = '',
    this.payoutAccountMaskedIdentifier = '',
    this.suspendedReason = '',
    this.suspendedAt,
    this.suspensionEndsAt,
    this.archivedAt,
    required this.completedBorrowings,
    required this.completedLendings,
    required this.completedServices,
    this.completedServicesProvided = 0,
    this.completedServicesRequested = 0,
    required this.termsAccepted,
    required this.locationVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String pendingEmail;
  final String phoneNumber;
  final bool emailVerified;
  final bool phoneVerified;
  final String role;
  final String verificationStatus;
  final String profileImageUrl;
  final String communityId;
  final String communityName;
  final String unitNumber;
  final double reputationScore;
  final int totalReviews;
  final double communityTrustScore;
  final bool trustedResident;
  final bool accountFlagged;
  final String trustFlagReason;
  final String accountStatus;
  final String payoutAccountStatus;
  final String xenditPayoutChannel;
  final String payoutAccountName;
  final String payoutAccountMaskedIdentifier;
  final String suspendedReason;
  final DateTime? suspendedAt;
  final DateTime? suspensionEndsAt;
  final DateTime? archivedAt;
  final int completedBorrowings;
  final int completedLendings;
  final int completedServices;
  final int completedServicesProvided;
  final int completedServicesRequested;
  final bool termsAccepted;
  final bool locationVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Verification feature: true when the resident has passed residency verification.
  bool get isVerifiedResident =>
      verificationStatus == AppConstants.verificationVerified;
  bool get isSuspended => accountStatus == AppConstants.accountStatusSuspended;
  bool isSuspensionActiveAt(DateTime now) =>
      isSuspended &&
      (suspensionEndsAt == null || now.isBefore(suspensionEndsAt!));
  bool get hasActiveSuspension => isSuspensionActiveAt(DateTime.now());
  bool get hasExpiredSuspension =>
      isSuspended &&
      suspensionEndsAt != null &&
      !DateTime.now().isBefore(suspensionEndsAt!);
  bool get isArchived => accountStatus == AppConstants.accountStatusArchived;
  bool get isDeleted => accountStatus == AppConstants.accountStatusDeleted;
  bool get isActiveAccount =>
      accountStatus.isEmpty ||
      accountStatus == AppConstants.accountStatusActive ||
      hasExpiredSuspension;
  bool get isResident => role == AppConstants.roleResident;
  bool get isCommunityAdmin => role == AppConstants.roleCommunityAdmin;
  bool get isSystemAdmin => role == AppConstants.roleSystemAdmin;
  bool get isAdmin => isCommunityAdmin || isSystemAdmin;
  bool get hasVerifiedPayoutAccount =>
      payoutAccountStatus == AppConstants.payoutAccountStatusVerified;
  String get fullName => '$firstName $lastName'.trim();

  /// Auth feature: detects an email-change request waiting for Firebase verification.
  bool get hasPendingEmailChange {
    final pending = pendingEmail.trim();
    return pending.isNotEmpty &&
        pending.toLowerCase() != email.trim().toLowerCase();
  }

  /// Auth/profile feature: creates an updated user object while preserving unchanged Firestore fields.
  AppUser copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
    String? pendingEmail,
    String? phoneNumber,
    bool? emailVerified,
    bool? phoneVerified,
    String? role,
    String? verificationStatus,
    String? profileImageUrl,
    String? communityId,
    String? communityName,
    String? unitNumber,
    double? reputationScore,
    int? totalReviews,
    double? communityTrustScore,
    bool? trustedResident,
    bool? accountFlagged,
    String? trustFlagReason,
    String? accountStatus,
    String? payoutAccountStatus,
    String? xenditPayoutChannel,
    String? payoutAccountName,
    String? payoutAccountMaskedIdentifier,
    String? suspendedReason,
    DateTime? suspendedAt,
    DateTime? suspensionEndsAt,
    DateTime? archivedAt,
    int? completedBorrowings,
    int? completedLendings,
    int? completedServices,
    int? completedServicesProvided,
    int? completedServicesRequested,
    bool? termsAccepted,
    bool? locationVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      unitNumber: unitNumber ?? this.unitNumber,
      reputationScore: reputationScore ?? this.reputationScore,
      totalReviews: totalReviews ?? this.totalReviews,
      communityTrustScore: communityTrustScore ?? this.communityTrustScore,
      trustedResident: trustedResident ?? this.trustedResident,
      accountFlagged: accountFlagged ?? this.accountFlagged,
      trustFlagReason: trustFlagReason ?? this.trustFlagReason,
      accountStatus: accountStatus ?? this.accountStatus,
      payoutAccountStatus: payoutAccountStatus ?? this.payoutAccountStatus,
      xenditPayoutChannel: xenditPayoutChannel ?? this.xenditPayoutChannel,
      payoutAccountName: payoutAccountName ?? this.payoutAccountName,
      payoutAccountMaskedIdentifier:
          payoutAccountMaskedIdentifier ?? this.payoutAccountMaskedIdentifier,
      suspendedReason: suspendedReason ?? this.suspendedReason,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      suspensionEndsAt: suspensionEndsAt ?? this.suspensionEndsAt,
      archivedAt: archivedAt ?? this.archivedAt,
      completedBorrowings: completedBorrowings ?? this.completedBorrowings,
      completedLendings: completedLendings ?? this.completedLendings,
      completedServices: completedServices ?? this.completedServices,
      completedServicesProvided:
          completedServicesProvided ?? this.completedServicesProvided,
      completedServicesRequested:
          completedServicesRequested ?? this.completedServicesRequested,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      locationVerified: locationVerified ?? this.locationVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Auth/profile DB model: serializes the user into the users/{uid} Firestore shape.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'role': role,
      'verificationStatus': verificationStatus,
      'profileImageUrl': profileImageUrl,
      'communityId': communityId,
      'communityName': communityName,
      'unitNumber': unitNumber,
      'reputationScore': reputationScore,
      'totalReviews': totalReviews,
      'communityTrustScore': communityTrustScore,
      'trustedResident': trustedResident,
      'accountFlagged': accountFlagged,
      'trustFlagReason': trustFlagReason,
      'accountStatus': accountStatus,
      'payoutAccountStatus': payoutAccountStatus,
      'xenditPayoutChannel': xenditPayoutChannel,
      'payoutAccountName': payoutAccountName,
      'payoutAccountMaskedIdentifier': payoutAccountMaskedIdentifier,
      'suspendedReason': suspendedReason,
      if (suspendedAt != null) 'suspendedAt': Timestamp.fromDate(suspendedAt!),
      if (suspensionEndsAt != null)
        'suspensionEndsAt': Timestamp.fromDate(suspensionEndsAt!),
      if (archivedAt != null) 'archivedAt': Timestamp.fromDate(archivedAt!),
      'completedBorrowings': completedBorrowings,
      'completedLendings': completedLendings,
      'completedServices': completedServices,
      'completedServicesProvided': completedServicesProvided,
      'completedServicesRequested': completedServicesRequested,
      'termsAccepted': termsAccepted,
      'locationVerified': locationVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Auth/profile DB model: converts users/{uid} Firestore data into an AppUser and normalizes legacy values.
  factory AppUser.fromMap(Map<String, dynamic> map) {
    final rawStatus = (map['verificationStatus'] as String?) ?? '';
    // Legacy Firestore value only — never use "approved" elsewhere in the app.
    final normalizedStatus = rawStatus == 'approved'
        ? AppConstants.verificationVerified
        : rawStatus;
    final names = _parseNames(map);

    return AppUser(
      uid: (map['uid'] as String?) ?? '',
      firstName: names.$1,
      lastName: names.$2,
      email: (map['email'] as String?) ?? '',
      pendingEmail: (map['pendingEmail'] as String?) ?? '',
      phoneNumber: (map['phoneNumber'] as String?) ?? '',
      emailVerified: map['emailVerified'] as bool? ?? false,
      phoneVerified: map['phoneVerified'] as bool? ?? false,
      role: (map['role'] as String?) ?? AppConstants.roleResident,
      verificationStatus: normalizedStatus,
      profileImageUrl: (map['profileImageUrl'] as String?) ?? '',
      communityId: (map['communityId'] as String?) ?? '',
      communityName: (map['communityName'] as String?) ?? '',
      unitNumber: (map['unitNumber'] as String?) ?? '',
      reputationScore: _parseDouble(map['reputationScore']),
      totalReviews: _parseInt(map['totalReviews']),
      communityTrustScore: _parseDouble(
        map['communityTrustScore'] ?? map['reputationScore'],
      ),
      trustedResident: map['trustedResident'] as bool? ?? false,
      accountFlagged: map['accountFlagged'] as bool? ?? false,
      trustFlagReason: (map['trustFlagReason'] as String?) ?? '',
      accountStatus:
          (map['accountStatus'] as String?) ?? AppConstants.accountStatusActive,
      payoutAccountStatus:
          (map['payoutAccountStatus'] as String?) ??
          AppConstants.payoutAccountStatusMissing,
      xenditPayoutChannel: (map['xenditPayoutChannel'] as String?) ?? '',
      payoutAccountName: (map['payoutAccountName'] as String?) ?? '',
      payoutAccountMaskedIdentifier:
          (map['payoutAccountMaskedIdentifier'] as String?) ?? '',
      suspendedReason: (map['suspendedReason'] as String?) ?? '',
      suspendedAt: _parseOptionalDate(map['suspendedAt']),
      suspensionEndsAt: _parseOptionalDate(map['suspensionEndsAt']),
      archivedAt: _parseOptionalDate(map['archivedAt']),
      completedBorrowings: _parseInt(map['completedBorrowings']),
      completedLendings: _parseInt(map['completedLendings']),
      completedServices: _parseInt(map['completedServices']),
      completedServicesProvided: _parseInt(map['completedServicesProvided']),
      completedServicesRequested: _parseInt(map['completedServicesRequested']),
      termsAccepted: map['termsAccepted'] as bool? ?? false,
      locationVerified: map['locationVerified'] as bool? ?? false,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  /// Auth/profile DB model: supports both new first/last name fields and legacy fullName records.
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

  /// Auth/profile DB model: safely parses integer counters from Firestore.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  /// Auth/profile DB model: safely parses score fields from Firestore.
  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  /// Auth/profile DB model: converts Firestore timestamp-like values into DateTime with a safe fallback.
  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Auth/profile DB model: converts optional timestamp-like values into nullable DateTime.
  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
