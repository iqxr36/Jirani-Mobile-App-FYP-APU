import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/providers/chat_provider.dart';
import 'package:jirani/resident/screens/chat/resident_chat_thread_view.dart';
import 'package:jirani/resident/screens/chat/resident_messages_view.dart';
import 'package:jirani/resident/screens/connections/resident_connections_view.dart';
import 'package:jirani/resident/screens/home/resident_marketplace_view.dart';
import 'package:jirani/resident/screens/home/resident_services_view.dart';
import 'package:jirani/shared/models/notification_model.dart';
import 'package:provider/provider.dart';

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
    default:
      break;
  }
}
