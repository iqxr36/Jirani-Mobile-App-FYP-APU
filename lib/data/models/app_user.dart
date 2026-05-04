import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
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
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final String verificationStatus;
  final String profileImageUrl;
  final String communityId;
  final String communityName;
  final String unitNumber;
  final int reputationScore;
  final int totalReviews;
  final int completedBorrowings;
  final int completedLendings;
  final int completedServices;
  final bool termsAccepted;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isVerifiedResident =>
      verificationStatus == AppConstants.verificationVerified;

  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? role,
    String? verificationStatus,
    String? profileImageUrl,
    String? communityId,
    String? communityName,
    String? unitNumber,
    int? reputationScore,
    int? totalReviews,
    int? completedBorrowings,
    int? completedLendings,
    int? completedServices,
    bool? termsAccepted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final rawStatus = (map['verificationStatus'] as String?) ?? '';
    // Legacy Firestore value only — never use "approved" elsewhere in the app.
    final normalizedStatus =
        rawStatus == 'approved' ? AppConstants.verificationVerified : rawStatus;

    return AppUser(
      uid: (map['uid'] as String?) ?? '',
      fullName: (map['fullName'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      phoneNumber: (map['phoneNumber'] as String?) ?? '',
      role: (map['role'] as String?) ?? AppConstants.roleResident,
      verificationStatus: normalizedStatus,
      profileImageUrl: (map['profileImageUrl'] as String?) ?? '',
      communityId: (map['communityId'] as String?) ?? '',
      communityName: (map['communityName'] as String?) ?? '',
      unitNumber: (map['unitNumber'] as String?) ?? '',
      reputationScore: _parseInt(map['reputationScore']),
      totalReviews: _parseInt(map['totalReviews']),
      completedBorrowings: _parseInt(map['completedBorrowings']),
      completedLendings: _parseInt(map['completedLendings']),
      completedServices: _parseInt(map['completedServices']),
      termsAccepted: map['termsAccepted'] as bool? ?? false,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
