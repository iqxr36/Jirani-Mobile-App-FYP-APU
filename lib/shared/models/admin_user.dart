import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jirani/core/constants/app_constants.dart';

/// Admin auth DB model: represents admins/{uid} or admin-shaped user records with role, scope, and permissions.
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
  /// Admin authorization: system admins can see/manage all communities, while community admins are scoped.
  bool get canManageAllCommunities => isSystemAdmin;

  /// Admin auth DB model: serializes admin profile and permissions into Firestore.
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

  /// Admin auth DB model: converts Firestore admin data into an AdminUser.
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

  /// Admin auth DB model: safely parses permissions arrays.
  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  /// Admin auth DB model: supports both boolean isActive and legacy status fields.
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
