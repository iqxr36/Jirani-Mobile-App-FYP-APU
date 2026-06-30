import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/models/notification_model.dart';

/// Notifications service: reads in-app notifications and provides client-created notification helpers.
class NotificationService {
  NotificationService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const int defaultLimit = 50;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(AppConstants.notificationsCollection);

  String? get _currentUid => _auth.currentUser?.uid;

  /// Notifications inbox: streams the latest notifications for one user.
  Stream<List<NotificationModel>> watchNotifications(
    String userId, {
    int limit = defaultLimit,
  }) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  /// Notifications badge: streams unread count for the resident/admin header badge.
  Stream<int> watchUnreadCount(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Notifications feature: creates a generic in-app notification, skipping self-notifications.
  Future<void> create({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? category,
    String? chatId,
    String? senderId,
    String? connectionId,
    String? borrowRequestId,
    String? serviceRequestId,
    String? postId,
    String? actorId,
  }) async {
    final resolvedActorId = actorId ?? _currentUid;
    if (resolvedActorId == null || resolvedActorId.isEmpty) {
      throw Exception('Missing signed-in user for notification.');
    }
    if (userId == resolvedActorId) return;

    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: type,
      title: title.trim(),
      body: body.trim(),
      read: false,
      createdAt: DateTime.now(),
      category: category ?? '',
      actorId: resolvedActorId,
      chatId: chatId ?? '',
      senderId: senderId ?? resolvedActorId,
      connectionId: connectionId ?? '',
      borrowRequestId: borrowRequestId ?? '',
      serviceRequestId: serviceRequestId ?? '',
      postId: postId ?? '',
    );

    await _notifications.add(notification.toCreateMap(actorId: resolvedActorId));
  }

  /// Chat notifications: creates the resident-facing chat message notification payload.
  Future<void> createChatMessageNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String chatId,
    required String preview,
  }) {
    return create(
      userId: recipientId,
      type: AppConstants.notificationTypeChatMessage,
      title: senderName.trim().isEmpty ? 'Resident' : senderName.trim(),
      body: preview,
      chatId: chatId,
      senderId: senderId,
      category: 'Messages',
    );
  }

  /// Notifications inbox: marks one notification as read.
  Future<void> markRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'read': true});
  }

  /// Notifications inbox: marks all unread notifications for one user as read in a batch.
  Future<void> markAllRead(String userId) async {
    final unread = await _notifications
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
