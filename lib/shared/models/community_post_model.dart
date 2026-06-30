import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';

/// Community news DB model: represents communityPosts/{postId} announcements, warnings, events, maintenance, and news.
class CommunityPostModel {
  const CommunityPostModel({
    required this.id,
    required this.communityId,
    required this.type,
    required this.title,
    required this.body,
    required this.status,
    required this.authorId,
    required this.authorName,
    required this.audience,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.imageUrl,
  });

  final String id;
  final String communityId;
  final String type;
  final String title;
  final String body;
  final String status;
  final String authorId;
  final String authorName;
  final String audience;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final String? imageUrl;

  bool get isPublished => status == AppConstants.communityPostStatusPublished;
  bool get isDraft => status == AppConstants.communityPostStatusDraft;

  /// Community news UI: maps post type constants to readable labels.
  String get displayCategory {
    return switch (type) {
      AppConstants.communityPostTypeAnnouncement => 'Announcement',
      AppConstants.communityPostTypeWarning => 'Warning',
      AppConstants.communityPostTypeEvent => 'Event',
      AppConstants.communityPostTypeMaintenance => 'Maintenance',
      _ => 'News',
    };
  }

  /// Community news UI: maps post type constants to icons.
  IconData get icon {
    return switch (type) {
      AppConstants.communityPostTypeAnnouncement =>
        Icons.notifications_active_outlined,
      AppConstants.communityPostTypeWarning => Icons.warning_amber_rounded,
      AppConstants.communityPostTypeEvent => Icons.event_available_outlined,
      AppConstants.communityPostTypeMaintenance => Icons.build_circle_outlined,
      _ => Icons.campaign_outlined,
    };
  }

  /// Community news UI: maps post type constants to accent colors.
  Color get accentColor {
    return switch (type) {
      AppConstants.communityPostTypeAnnouncement => const Color(0xFF006D77),
      AppConstants.communityPostTypeWarning => const Color(0xFFB42318),
      AppConstants.communityPostTypeEvent => const Color(0xFFE29578),
      AppConstants.communityPostTypeMaintenance => const Color(0xFFD97706),
      _ => const Color(0xFF006D77),
    };
  }

  /// Community notifications: maps post type to the notification type sent when a post is published.
  String get notificationType {
    return switch (type) {
      AppConstants.communityPostTypeAnnouncement =>
        AppConstants.notificationTypeCommunityAnnouncement,
      AppConstants.communityPostTypeWarning =>
        AppConstants.notificationTypeCommunityWarning,
      AppConstants.communityPostTypeEvent =>
        AppConstants.notificationTypeCommunityEvent,
      AppConstants.communityPostTypeMaintenance =>
        AppConstants.notificationTypeMaintenanceNotice,
      _ => AppConstants.notificationTypeCommunityNews,
    };
  }

  /// Community news DB model: converts Firestore post data into a CommunityPostModel.
  factory CommunityPostModel.fromMap(String id, Map<String, dynamic> data) {
    return CommunityPostModel(
      id: id,
      communityId: (data['communityId'] as String?) ?? '',
      type: (data['type'] as String?) ?? AppConstants.communityPostTypeNews,
      title: ((data['title'] as String?) ?? '').trim(),
      body: ((data['body'] as String?) ?? '').trim(),
      status:
          (data['status'] as String?) ?? AppConstants.communityPostStatusDraft,
      authorId: (data['authorId'] as String?) ?? '',
      authorName: ((data['authorName'] as String?) ?? 'Admin').trim(),
      audience: ((data['audience'] as String?) ?? 'All residents').trim(),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      publishedAt: _parseNullableDate(data['publishedAt']),
      imageUrl: (data['imageUrl'] as String?)?.trim(),
    );
  }

  /// Community news DB model: serializes a post draft/published post for Firestore creation.
  Map<String, dynamic> toCreateMap() {
    return {
      'communityId': communityId,
      'type': type,
      'title': title,
      'body': body,
      'status': status,
      'authorId': authorId,
      'authorName': authorName,
      'audience': audience,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value == null) return null;
    return _parseDate(value);
  }
}
