// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : notification_repository.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,25-June-2026
// Last Edited on  : Saturday,18-July-2026

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
