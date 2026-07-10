import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';

/// Notifications DB model: represents notifications/{notificationId} used by in-app inbox, badges, and deep links.
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
    this.itemId = '',
    this.serviceId = '',
    this.verificationRequestId = '',
    this.residentId = '',
    this.reportId = '',
    this.communityId = '',
    this.ocrDecision = '',
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
  final String itemId;
  final String serviceId;
  final String verificationRequestId;
  final String residentId;
  final String reportId;
  final String communityId;
  final String ocrDecision;

  bool get unread => !read;

  /// Notifications feature: groups community post notifications for inbox presentation.
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

  /// Notifications UI: chooses a visible category from stored data or notification type.
  String get displayCategory {
    final value = category.trim();
    if (value.isNotEmpty) return value;
    return _categoryForType(type);
  }

  IconData get icon => _iconForType(type);

  Color get accentColor => _accentForType(type);

  /// Notifications UI: formats the timestamp into short relative text for the inbox.
  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Notifications DB model: converts Firestore notification data into a NotificationModel.
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
      itemId: (data['itemId'] as String?) ?? '',
      serviceId: (data['serviceId'] as String?) ?? '',
      verificationRequestId:
          (data['verificationRequestId'] as String?) ?? '',
      residentId: (data['residentId'] as String?) ?? '',
      reportId: (data['reportId'] as String?) ?? '',
      communityId: (data['communityId'] as String?) ?? '',
      ocrDecision: (data['ocrDecision'] as String?) ?? '',
    );
  }

  /// Notifications DB model: serializes a notification for Firestore creation with only relevant deep-link ids.
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
      if (itemId.isNotEmpty) 'itemId': itemId,
      if (serviceId.isNotEmpty) 'serviceId': serviceId,
      if (verificationRequestId.isNotEmpty)
        'verificationRequestId': verificationRequestId,
      if (residentId.isNotEmpty) 'residentId': residentId,
      if (reportId.isNotEmpty) 'reportId': reportId,
      if (communityId.isNotEmpty) 'communityId': communityId,
      if (ocrDecision.isNotEmpty) 'ocrDecision': ocrDecision,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Notifications UI: maps notification type constants to inbox categories.
  static String _categoryForType(String type) {
    return switch (type) {
      AppConstants.notificationTypeAdminWarning => 'Admin',
      AppConstants.notificationTypeChatMessage => 'Messages',
      AppConstants.notificationTypeConnectionRequest ||
      AppConstants.notificationTypeConnectionAccepted => 'Community',
      AppConstants.notificationTypeNeighborNewItem ||
      AppConstants.notificationTypeNeighborNewService ||
      AppConstants.notificationTypeNeighborTrustWarning => 'Neighbors',
      AppConstants.notificationTypeBorrowRequest ||
      AppConstants.notificationTypeBorrowApproved ||
      AppConstants.notificationTypeBorrowRejected ||
      AppConstants.notificationTypeBorrowDepositResolved ||
      AppConstants.notificationTypeBorrowPayoutReady ||
      AppConstants.notificationTypeBorrowPayoutPaid => 'Marketplace',
      AppConstants.notificationTypeServiceRequest ||
      AppConstants.notificationTypeServiceAccepted ||
      AppConstants.notificationTypeServiceRejected ||
      AppConstants.notificationTypeServicePaymentReceived ||
      AppConstants.notificationTypeServiceArrivalCode ||
      AppConstants.notificationTypeServiceArrivalVerified ||
      AppConstants.notificationTypeServiceCompleted ||
      AppConstants.notificationTypeServiceDisputed ||
      AppConstants.notificationTypeServicePayoutSent ||
      AppConstants.notificationTypeServicePayoutFailed ||
      AppConstants.notificationTypeServiceRefunded ||
      AppConstants.notificationTypeServiceAdminResolved => 'Services',
      AppConstants.notificationTypeCommunityEvent => 'Events',
      AppConstants.notificationTypeMaintenanceNotice => 'Maintenance',
      AppConstants.notificationTypeCommunityNews => 'News',
      AppConstants.notificationTypeCommunityAnnouncement => 'Announcements',
      AppConstants.notificationTypeCommunityWarning => 'Warnings',
      AppConstants.notificationTypeVerificationOcrMatched ||
      AppConstants.notificationTypeVerificationOcrReview => 'Verification',
      AppConstants.notificationTypeAdminReport => 'Reports',
      AppConstants.notificationTypeMarketplaceListingArchived ||
      AppConstants.notificationTypeMarketplaceListingRestored => 'Marketplace',
      _ => 'Updates',
    };
  }

  /// Notifications UI: maps notification type constants to Material icons.
  static IconData _iconForType(String type) {
    return switch (type) {
      AppConstants.notificationTypeAdminWarning => Icons.campaign_rounded,
      AppConstants.notificationTypeChatMessage =>
        Icons.chat_bubble_outline_rounded,
      AppConstants.notificationTypeConnectionRequest ||
      AppConstants.notificationTypeConnectionAccepted =>
        Icons.groups_2_outlined,
      AppConstants.notificationTypeNeighborNewItem =>
        Icons.inventory_2_outlined,
      AppConstants.notificationTypeNeighborNewService =>
        Icons.home_repair_service_outlined,
      AppConstants.notificationTypeNeighborTrustWarning =>
        Icons.shield_outlined,
      AppConstants.notificationTypeBorrowRequest ||
      AppConstants.notificationTypeBorrowApproved ||
      AppConstants.notificationTypeBorrowRejected ||
      AppConstants.notificationTypeBorrowDepositResolved ||
      AppConstants.notificationTypeBorrowPayoutReady ||
      AppConstants.notificationTypeBorrowPayoutPaid =>
        Icons.inventory_2_outlined,
      AppConstants.notificationTypeServiceRequest ||
      AppConstants.notificationTypeServiceAccepted ||
      AppConstants.notificationTypeServiceRejected ||
      AppConstants.notificationTypeServicePaymentReceived ||
      AppConstants.notificationTypeServiceArrivalCode ||
      AppConstants.notificationTypeServiceArrivalVerified ||
      AppConstants.notificationTypeServiceCompleted ||
      AppConstants.notificationTypeServiceDisputed ||
      AppConstants.notificationTypeServicePayoutSent ||
      AppConstants.notificationTypeServicePayoutFailed ||
      AppConstants.notificationTypeServiceRefunded ||
      AppConstants.notificationTypeServiceAdminResolved =>
        Icons.home_repair_service_outlined,
      AppConstants.notificationTypeCommunityEvent =>
        Icons.event_available_outlined,
      AppConstants.notificationTypeMaintenanceNotice => Icons.build_circle_outlined,
      AppConstants.notificationTypeCommunityNews => Icons.newspaper_outlined,
      AppConstants.notificationTypeCommunityAnnouncement =>
        Icons.notifications_active_outlined,
      AppConstants.notificationTypeCommunityWarning =>
        Icons.warning_amber_rounded,
      AppConstants.notificationTypeVerificationOcrMatched =>
        Icons.fact_check_outlined,
      AppConstants.notificationTypeVerificationOcrReview =>
        Icons.manage_search_rounded,
      AppConstants.notificationTypeAdminReport =>
        Icons.report_problem_outlined,
      AppConstants.notificationTypeMarketplaceListingArchived =>
        Icons.archive_outlined,
      AppConstants.notificationTypeMarketplaceListingRestored =>
        Icons.unarchive_outlined,
      _ => Icons.notifications_active_outlined,
    };
  }

  /// Notifications UI: maps notification type constants to accent colors.
  static Color _accentForType(String type) {
    return switch (type) {
      AppConstants.notificationTypeAdminWarning => const Color(0xFFB42318),
      AppConstants.notificationTypeChatMessage => const Color(0xFF006D77),
      AppConstants.notificationTypeConnectionRequest ||
      AppConstants.notificationTypeConnectionAccepted =>
        const Color(0xFF2F855A),
      AppConstants.notificationTypeNeighborNewItem => const Color(0xFFE29578),
      AppConstants.notificationTypeNeighborNewService => const Color(0xFF7C3AED),
      AppConstants.notificationTypeNeighborTrustWarning =>
        const Color(0xFFB42318),
      AppConstants.notificationTypeBorrowRequest ||
      AppConstants.notificationTypeBorrowApproved ||
      AppConstants.notificationTypeBorrowRejected => const Color(0xFFE29578),
      AppConstants.notificationTypeBorrowDepositResolved ||
      AppConstants.notificationTypeBorrowPayoutReady ||
      AppConstants.notificationTypeBorrowPayoutPaid => const Color(0xFF006D77),
      AppConstants.notificationTypeServiceRequest ||
      AppConstants.notificationTypeServiceAccepted ||
      AppConstants.notificationTypeServiceRejected ||
      AppConstants.notificationTypeServicePaymentReceived ||
      AppConstants.notificationTypeServiceArrivalCode ||
      AppConstants.notificationTypeServiceArrivalVerified ||
      AppConstants.notificationTypeServiceCompleted ||
      AppConstants.notificationTypeServiceDisputed ||
      AppConstants.notificationTypeServicePayoutSent ||
      AppConstants.notificationTypeServicePayoutFailed ||
      AppConstants.notificationTypeServiceRefunded ||
      AppConstants.notificationTypeServiceAdminResolved =>
        const Color(0xFF7C3AED),
      AppConstants.notificationTypeCommunityEvent => const Color(0xFFE29578),
      AppConstants.notificationTypeMaintenanceNotice =>
        const Color(0xFFD97706),
      AppConstants.notificationTypeCommunityNews => const Color(0xFF006D77),
      AppConstants.notificationTypeCommunityAnnouncement =>
        const Color(0xFF006D77),
      AppConstants.notificationTypeCommunityWarning => const Color(0xFFB42318),
      AppConstants.notificationTypeVerificationOcrMatched =>
        const Color(0xFF2F855A),
      AppConstants.notificationTypeVerificationOcrReview =>
        const Color(0xFFB7791F),
      AppConstants.notificationTypeAdminReport => const Color(0xFFB42318),
      AppConstants.notificationTypeMarketplaceListingArchived =>
        const Color(0xFFD97706),
      AppConstants.notificationTypeMarketplaceListingRestored =>
        const Color(0xFF2F855A),
      _ => const Color(0xFF2F855A),
    };
  }
}
