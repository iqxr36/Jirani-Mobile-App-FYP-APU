import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jirani/core/constants/app_constants.dart';

class AdminUser {
  const AdminUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.communityId,
    required this.communityName,
    required this.profileImageUrl,
    required this.permissions,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final String communityId;
  final String communityName;
  final String profileImageUrl;
  final List<String> permissions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCommunityAdmin => role == AppConstants.roleCommunityAdmin;
  bool get isSystemAdmin => role == AppConstants.roleSystemAdmin;
  bool get canManageAllCommunities => isSystemAdmin;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'communityId': communityId,
      'communityName': communityName,
      'profileImageUrl': profileImageUrl,
      'permissions': permissions,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      uid: (map['uid'] as String?) ?? '',
      fullName: (map['fullName'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      phoneNumber: (map['phoneNumber'] as String?) ?? '',
      role: (map['role'] as String?) ?? AppConstants.roleCommunityAdmin,
      communityId: (map['communityId'] as String?) ?? '',
      communityName: (map['communityName'] as String?) ?? '',
      profileImageUrl: (map['profileImageUrl'] as String?) ?? '',
      permissions: _parseStringList(map['permissions']),
      isActive: _parseActive(map),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static bool _parseActive(Map<String, dynamic> map) {
    final active = map['isActive'];
    if (active is bool) return active;
    final status = (map['status'] as String?)?.trim().toLowerCase() ?? '';
    if (status.isEmpty) return true;
    return status == 'active' || status == 'enabled';
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
