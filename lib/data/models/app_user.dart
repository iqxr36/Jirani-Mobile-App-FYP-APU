import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jirani/core/constants/app_constants.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.emailVerified,
    required this.phoneVerified,
    required this.role,
    required this.verificationStatus,
    required this.profileImageUrl,
    required this.communityId,
    required this.communityName,
    required this.unitNumber,
    required this.reputationScore,
    required this.totalReviews,
    required this.completedBorrowings,
    required this.completedLendings,
    required this.completedServices,
    required this.termsAccepted,
    required this.locationVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String fullName;
  final String email;
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
  final int completedBorrowings;
  final int completedLendings;
  final int completedServices;
  final bool termsAccepted;
  final bool locationVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isVerifiedResident =>
      verificationStatus == AppConstants.verificationVerified;
  bool get isResident => role == AppConstants.roleResident;
  bool get isCommunityAdmin => role == AppConstants.roleCommunityAdmin;
  bool get isSystemAdmin => role == AppConstants.roleSystemAdmin;
  bool get isAdmin => isCommunityAdmin || isSystemAdmin;

  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
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
    int? completedBorrowings,
    int? completedLendings,
    int? completedServices,
    bool? termsAccepted,
    bool? locationVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
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
      completedBorrowings: completedBorrowings ?? this.completedBorrowings,
      completedLendings: completedLendings ?? this.completedLendings,
      completedServices: completedServices ?? this.completedServices,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      locationVerified: locationVerified ?? this.locationVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
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
      'completedBorrowings': completedBorrowings,
      'completedLendings': completedLendings,
      'completedServices': completedServices,
      'termsAccepted': termsAccepted,
      'locationVerified': locationVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final rawStatus = (map['verificationStatus'] as String?) ?? '';
    // Legacy Firestore value only — never use "approved" elsewhere in the app.
    final normalizedStatus = rawStatus == 'approved'
        ? AppConstants.verificationVerified
        : rawStatus;

    return AppUser(
      uid: (map['uid'] as String?) ?? '',
      fullName: (map['fullName'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
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
      completedBorrowings: _parseInt(map['completedBorrowings']),
      completedLendings: _parseInt(map['completedLendings']),
      completedServices: _parseInt(map['completedServices']),
      termsAccepted: map['termsAccepted'] as bool? ?? false,
      locationVerified: map['locationVerified'] as bool? ?? false,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
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
