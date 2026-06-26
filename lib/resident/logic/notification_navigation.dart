import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/providers/chat_provider.dart';
import 'package:jirani/resident/screens/chat/resident_chat_thread_view.dart';
import 'package:jirani/resident/screens/chat/resident_messages_view.dart';
import 'package:jirani/resident/screens/connections/resident_connections_view.dart';
import 'package:jirani/resident/screens/home/resident_home_view.dart';
import 'package:jirani/resident/screens/home/resident_marketplace_view.dart';
import 'package:jirani/resident/screens/home/resident_services_view.dart';
import 'package:jirani/resident/screens/notifications/resident_notifications_view.dart';
import 'package:jirani/shared/models/notification_model.dart';
import 'package:provider/provider.dart';

Future<void> navigateFromPushData(
  BuildContext context,
  Map<String, dynamic> data,
) async {
  final type = (data['type'] as String?)?.trim() ?? '';
  if (type.isEmpty) {
    await _openNotificationsInbox(context);
    return;
  }

  await navigateFromNotification(
    context,
    NotificationModel(
      id: '',
      userId: '',
      type: type,
      title: '',
      body: '',
      read: false,
      createdAt: DateTime.now(),
      chatId: (data['chatId'] as String?) ?? '',
      connectionId: (data['connectionId'] as String?) ?? '',
      borrowRequestId: (data['borrowRequestId'] as String?) ?? '',
      serviceRequestId: (data['serviceRequestId'] as String?) ?? '',
      postId: (data['postId'] as String?) ?? '',
    ),
  );
}

Future<void> navigateFromNotification(
  BuildContext context,
  NotificationModel notification,
) async {
  switch (notification.type) {
    case AppConstants.notificationTypeChatMessage:
      final chatId = notification.chatId.trim();
      if (chatId.isEmpty) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const ResidentMessagesView(),
          ),
        );
        return;
      }
      final chat = context.read<ChatProvider>().chatById(chatId);
      if (chat != null) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ResidentChatThreadView(initialChat: chat),
          ),
        );
      } else {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const ResidentMessagesView(),
          ),
        );
      }
    case AppConstants.notificationTypeConnectionRequest:
    case AppConstants.notificationTypeConnectionAccepted:
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const ResidentConnectionsView(),
        ),
      );
    case AppConstants.notificationTypeBorrowRequest:
    case AppConstants.notificationTypeBorrowApproved:
    case AppConstants.notificationTypeBorrowRejected:
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const ResidentMarketplaceView(),
        ),
      );
    case AppConstants.notificationTypeServiceRequest:
    case AppConstants.notificationTypeServiceAccepted:
    case AppConstants.notificationTypeServiceRejected:
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const ResidentServicesView(),
        ),
      );
    case AppConstants.notificationTypeCommunityNews:
    case AppConstants.notificationTypeCommunityAnnouncement:
    case AppConstants.notificationTypeCommunityEvent:
    case AppConstants.notificationTypeMaintenanceNotice:
    case AppConstants.notificationTypeCommunityWarning:
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const ResidentHomeView(),
        ),
      );
    default:
      await _openNotificationsInbox(context);
  }
}

Future<void> _openNotificationsInbox(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const ResidentNotificationsView(),
    ),
  );
}
