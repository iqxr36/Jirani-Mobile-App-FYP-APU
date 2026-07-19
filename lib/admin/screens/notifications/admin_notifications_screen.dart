// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_notifications_screen.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Monday,29-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/shared/data/repositories/notification_repository.dart';
import 'package:jirani/shared/models/notification_model.dart';

// Admin notifications UI feature: lists admin notifications and lets admins review unread/handled items.
class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({
    super.key,
    required this.adminUid,
    required this.onNotificationSelected,
  });

  final String adminUid;
  final ValueChanged<NotificationModel> onNotificationSelected;

  @override
  Widget build(BuildContext context) {
    final repository = NotificationRepository();
    final uid = adminUid.trim();

    return AdminPageScroll(
      children: [
        AdminControlBar(
          title: 'Notifications',
          subtitle:
              'Verification, report, and system alerts that need admin attention.',
          controls: [
            TextButton.icon(
              onPressed: uid.isEmpty ? null : () => repository.markAllRead(uid),
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Mark all read'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (uid.isEmpty)
          const AdminInlineAlert(message: 'Admin account is not loaded yet.')
        else
          StreamBuilder<List<NotificationModel>>(
            stream: repository.watchNotifications(uid),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? const <NotificationModel>[];
              if (snapshot.connectionState == ConnectionState.waiting &&
                  notifications.isEmpty) {
                return const AdminPanel(
                  title: 'Notification Inbox',
                  child: SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              if (notifications.isEmpty) {
                return const AdminPanel(
                  title: 'Notification Inbox',
                  child: AdminEmptyPanelMessage(
                    icon: Icons.notifications_none_rounded,
                    title: 'No notifications yet',
                    body:
                        'OCR verification results, report alerts, and admin tasks will appear here.',
                  ),
                );
              }

              return AdminPanel(
                title: 'Notification Inbox',
                action: notifications.length.toString(),
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AdminColors.border),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return AdminNotificationListTile(
                      notification: notification,
                      onTap: () async {
                        await repository.markRead(notification.id);
                        if (!context.mounted) return;
                        onNotificationSelected(notification);
                      },
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}

// Admin notifications UI feature: renders one notification row with metadata and read state.
class AdminNotificationListTile extends StatelessWidget {
  const AdminNotificationListTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canNavigate = notification.verificationRequestId.trim().isNotEmpty ||
        notification.reportId.trim().isNotEmpty;
    return Material(
      color: notification.unread
          ? AdminColors.primary.withValues(alpha: 0.05)
          : Colors.transparent,
      child: InkWell(
        onTap: canNavigate ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: notification.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AdminColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          notification.relativeTime,
                          style: const TextStyle(
                            color: AdminColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _NotificationMetaChip(
                          label: notification.displayCategory,
                          color: notification.accentColor,
                        ),
                        if (notification.unread)
                          _NotificationMetaChip(
                            label: 'Unread',
                            color: AdminColors.primary,
                          ),
                        if (canNavigate)
                          const _NotificationMetaChip(
                            label: 'Open task',
                            color: AdminColors.success,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationMetaChip extends StatelessWidget {
  const _NotificationMetaChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
