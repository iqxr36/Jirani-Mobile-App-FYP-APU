import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.category = '',
    this.actorId = '',
    this.chatId = '',
    this.senderId = '',
    this.connectionId = '',
    this.borrowRequestId = '',
    this.serviceRequestId = '',
    this.postId = '',
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final String category;
  final String actorId;
  final String chatId;
  final String senderId;
  final String connectionId;
  final String borrowRequestId;
  final String serviceRequestId;
  final String postId;

  bool get unread => !read;

  bool get isCommunityUpdate {
    return switch (type) {
      AppConstants.notificationTypeCommunityNews ||
      AppConstants.notificationTypeCommunityAnnouncement ||
      AppConstants.notificationTypeCommunityWarning ||
      AppConstants.notificationTypeCommunityEvent ||
      AppConstants.notificationTypeMaintenanceNotice => true,
      _ => false,
    };
  }

  String get displayCategory {
    final value = category.trim();
    if (value.isNotEmpty) return value;
    return _categoryForType(type);
  }

  IconData get icon => _iconForType(type);

  Color get accentColor => _accentForType(type);

  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> data) {
    return NotificationModel(
      id: id,
      userId: (data['userId'] as String?) ?? '',
      type: (data['type'] as String?) ?? '',
      title: ((data['title'] as String?) ?? 'Notification').trim(),
      body: ((data['body'] as String?) ?? '').trim(),
      read: data['read'] == true,
      createdAt: _parseDate(data['createdAt']),
      category: (data['category'] as String?) ?? '',
      actorId: (data['actorId'] as String?) ?? '',
      chatId: (data['chatId'] as String?) ?? '',
      senderId: (data['senderId'] as String?) ?? '',
      connectionId: (data['connectionId'] as String?) ?? '',
      borrowRequestId: (data['borrowRequestId'] as String?) ?? '',
      serviceRequestId: (data['serviceRequestId'] as String?) ?? '',
      postId: (data['postId'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toCreateMap({
    required String actorId,
  }) {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'actorId': actorId,
      if (category.trim().isNotEmpty) 'category': category.trim(),
      if (chatId.isNotEmpty) 'chatId': chatId,
      if (senderId.isNotEmpty) 'senderId': senderId,
      if (connectionId.isNotEmpty) 'connectionId': connectionId,
      if (borrowRequestId.isNotEmpty) 'borrowRequestId': borrowRequestId,
      if (serviceRequestId.isNotEmpty) 'serviceRequestId': serviceRequestId,
      if (postId.isNotEmpty) 'postId': postId,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static String _categoryForType(String type) {
    return switch (type) {
      AppConstants.notificationTypeAdminWarning => 'Admin',
      AppConstants.notificationTypeChatMessage => 'Messages',
      AppConstants.notificationTypeConnectionRequest ||
      AppConstants.notificationTypeConnectionAccepted => 'Community',
      AppConstants.notificationTypeBorrowRequest ||
      AppConstants.notificationTypeBorrowApproved ||
      AppConstants.notificationTypeBorrowRejected => 'Marketplace',
      AppConstants.notificationTypeServiceRequest ||
      AppConstants.notificationTypeServiceAccepted ||
      AppConstants.notificationTypeServiceRejected => 'Services',
      AppConstants.notificationTypeCommunityEvent => 'Events',
      AppConstants.notificationTypeMaintenanceNotice => 'Maintenance',
      AppConstants.notificationTypeCommunityNews => 'News',
      AppConstants.notificationTypeCommunityAnnouncement => 'Announcements',
      AppConstants.notificationTypeCommunityWarning => 'Warnings',
      _ => 'Updates',
    };
  }

  static IconData _iconForType(String type) {
    return switch (type) {
      AppConstants.notificationTypeAdminWarning => Icons.campaign_rounded,
      AppConstants.notificationTypeChatMessage =>
        Icons.chat_bubble_outline_rounded,
      AppConstants.notificationTypeConnectionRequest ||
      AppConstants.notificationTypeConnectionAccepted =>
        Icons.groups_2_outlined,
      AppConstants.notificationTypeBorrowRequest ||
      AppConstants.notificationTypeBorrowApproved ||
      AppConstants.notificationTypeBorrowRejected =>
        Icons.inventory_2_outlined,
      AppConstants.notificationTypeServiceRequest ||
      AppConstants.notificationTypeServiceAccepted ||
      AppConstants.notificationTypeServiceRejected =>
        Icons.home_repair_service_outlined,
      AppConstants.notificationTypeCommunityEvent =>
        Icons.event_available_outlined,
      AppConstants.notificationTypeMaintenanceNotice => Icons.build_circle_outlined,
      AppConstants.notificationTypeCommunityNews => Icons.newspaper_outlined,
      AppConstants.notificationTypeCommunityAnnouncement =>
        Icons.notifications_active_outlined,
      AppConstants.notificationTypeCommunityWarning =>
        Icons.warning_amber_rounded,
      _ => Icons.notifications_active_outlined,
    };
  }

  static Color _accentForType(String type) {
    return switch (type) {
      AppConstants.notificationTypeAdminWarning => const Color(0xFFB42318),
      AppConstants.notificationTypeChatMessage => const Color(0xFF006D77),
      AppConstants.notificationTypeConnectionRequest ||
      AppConstants.notificationTypeConnectionAccepted =>
        const Color(0xFF2F855A),
      AppConstants.notificationTypeBorrowRequest ||
      AppConstants.notificationTypeBorrowApproved ||
      AppConstants.notificationTypeBorrowRejected => const Color(0xFFE29578),
      AppConstants.notificationTypeServiceRequest ||
      AppConstants.notificationTypeServiceAccepted ||
      AppConstants.notificationTypeServiceRejected =>
        const Color(0xFF7C3AED),
      AppConstants.notificationTypeCommunityEvent => const Color(0xFFE29578),
      AppConstants.notificationTypeMaintenanceNotice =>
        const Color(0xFFD97706),
      AppConstants.notificationTypeCommunityNews => const Color(0xFF006D77),
      AppConstants.notificationTypeCommunityAnnouncement =>
        const Color(0xFF006D77),
      AppConstants.notificationTypeCommunityWarning => const Color(0xFFB42318),
      _ => const Color(0xFF2F855A),
    };
  }
}
