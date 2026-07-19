// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : notification_details_sheet.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,03-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/shared/models/notification_model.dart';

/// Notifications UI: Displays detailed information for specific notification types like admin warnings, reports, and listing removals.
class NotificationDetailsSheet extends StatelessWidget {
  const NotificationDetailsSheet({super.key, required this.notification});

  final NotificationModel notification;

  /// Shows this sheet as a modal bottom sheet.
  static Future<void> show(
      BuildContext context, NotificationModel notification) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          NotificationDetailsSheet(notification: notification),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: notification.accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.icon,
                  color: notification.accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${notification.displayCategory} • ${DateFormat('d MMM yyyy, h:mm a').format(notification.createdAt)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: context.appMuted),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 24,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Text(
            'Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.appMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            notification.body,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: context.appInk,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Acknowledge',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
