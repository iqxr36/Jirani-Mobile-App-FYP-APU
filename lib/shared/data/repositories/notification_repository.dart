import 'package:jirani/shared/models/notification_model.dart';
import 'package:jirani/shared/services/notification_service.dart';

// Notification data layer: exposes notification streams and read actions to resident providers.
class NotificationRepository {
  NotificationRepository({NotificationService? service})
    : _service = service ?? NotificationService();

  final NotificationService _service;

  // Notification feature: streams newest notifications for one resident.
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _service.watchNotifications(userId);
  }

  // Notification feature: streams unread count for badges in the resident shell.
  Stream<int> watchUnreadCount(String userId) {
    return _service.watchUnreadCount(userId);
  }

  // Notification feature: marks one notification read.
  Future<void> markRead(String notificationId) {
    return _service.markRead(notificationId);
  }

  // Notification feature: marks all notifications for a resident as read.
  Future<void> markAllRead(String userId) {
    return _service.markAllRead(userId);
  }
}
