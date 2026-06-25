import 'package:jirani/shared/models/notification_model.dart';
import 'package:jirani/shared/services/notification_service.dart';

class NotificationRepository {
  NotificationRepository({NotificationService? service})
    : _service = service ?? NotificationService();

  final NotificationService _service;

  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _service.watchNotifications(userId);
  }

  Stream<int> watchUnreadCount(String userId) {
    return _service.watchUnreadCount(userId);
  }

  Future<void> markRead(String notificationId) {
    return _service.markRead(notificationId);
  }

  Future<void> markAllRead(String userId) {
    return _service.markAllRead(userId);
  }
}
