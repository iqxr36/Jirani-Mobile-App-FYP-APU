import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/resident/providers/borrow_request_provider.dart';
import 'package:jirani/resident/providers/chat_provider.dart';
import 'package:jirani/resident/providers/service_provider.dart' as services;
import 'package:jirani/resident/screens/chat/resident_chat_thread_view.dart';
import 'package:jirani/resident/screens/chat/resident_messages_view.dart';
import 'package:jirani/resident/screens/connections/resident_connections_view.dart';
import 'package:jirani/resident/screens/home/community_post_detail_view.dart';
import 'package:jirani/resident/screens/home/resident_home_view.dart';
import 'package:jirani/resident/screens/home/resident_marketplace_view.dart';
import 'package:jirani/resident/screens/home/resident_services_view.dart';
import 'package:jirani/resident/screens/marketplace/resident_item_listing_view.dart';
import 'package:jirani/resident/screens/notifications/resident_notifications_view.dart';
import 'package:jirani/shared/data/repositories/item_repository.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/models/notification_model.dart';
import 'package:provider/provider.dart';
import 'package:jirani/resident/screens/notifications/notification_details_sheet.dart';

/// Notifications feature: converts raw FCM push payload data into the same model used by in-app notification taps.
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
      itemId: (data['itemId'] as String?) ?? '',
      serviceId: (data['serviceId'] as String?) ?? '',
      residentId: (data['residentId'] as String?) ?? '',
    ),
  );
}

/// Notifications feature: routes each notification type to its resident destination screen.
Future<void> navigateFromNotification(
  BuildContext context,
  NotificationModel notification,
) async {
  switch (notification.type) {
    case AppConstants.notificationTypeChatMessage:
      await _openChatNotification(context, notification);
      return;
    case AppConstants.notificationTypeConnectionRequest:
    case AppConstants.notificationTypeConnectionAccepted:
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const ResidentConnectionsView(),
        ),
      );
      return;
    case AppConstants.notificationTypeBorrowRequest:
    case AppConstants.notificationTypeBorrowApproved:
    case AppConstants.notificationTypeBorrowRejected:
    case AppConstants.notificationTypeBorrowDepositResolved:
    case AppConstants.notificationTypeBorrowPayoutReady:
    case AppConstants.notificationTypeBorrowPayoutPaid:
      await _openBorrowNotification(context, notification);
      return;
    case AppConstants.notificationTypeServiceRequest:
    case AppConstants.notificationTypeServiceAccepted:
    case AppConstants.notificationTypeServiceRejected:
    case AppConstants.notificationTypeServicePaymentReceived:
    case AppConstants.notificationTypeServiceArrivalCode:
    case AppConstants.notificationTypeServiceArrivalVerified:
    case AppConstants.notificationTypeServiceCompleted:
    case AppConstants.notificationTypeServiceDisputed:
    case AppConstants.notificationTypeServicePayoutSent:
    case AppConstants.notificationTypeServicePayoutFailed:
    case AppConstants.notificationTypeServiceRefunded:
    case AppConstants.notificationTypeServiceAdminResolved:
      await _openServiceNotification(context, notification);
      return;
    case AppConstants.notificationTypeCommunityNews:
    case AppConstants.notificationTypeCommunityAnnouncement:
    case AppConstants.notificationTypeCommunityEvent:
    case AppConstants.notificationTypeMaintenanceNotice:
    case AppConstants.notificationTypeCommunityWarning:
      await _openCommunityNotification(context, notification);
      return;
    case AppConstants.notificationTypeNeighborNewItem:
      await _openNeighborItemNotification(context, notification);
      return;
    case AppConstants.notificationTypeNeighborNewService:
      await _openNeighborServiceNotification(context, notification);
      return;
    case AppConstants.notificationTypeNeighborTrustWarning:
      await NotificationDetailsSheet.show(context, notification);
      return;
    case AppConstants.notificationTypeAdminWarning:
    case AppConstants.notificationTypeAdminReport:
    case AppConstants.notificationTypeMarketplaceListingArchived:
    case AppConstants.notificationTypeMarketplaceListingRestored:
      await NotificationDetailsSheet.show(context, notification);
      return;
    default:
      await _openNotificationsInbox(context);
  }
}

/// Chat notifications: opens the specific thread when available, otherwise falls back to the messages inbox.
Future<void> _openChatNotification(
  BuildContext context,
  NotificationModel notification,
) async {
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
    return;
  }

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const ResidentMessagesView(),
    ),
  );
}

/// Services notifications: opens provider or requester transaction view based on notification type and user role.
Future<void> _openServiceNotification(
  BuildContext context,
  NotificationModel notification,
) async {
  final requestId = notification.serviceRequestId.trim();
  if (requestId.isEmpty) {
    await _openServicesBrowse(context);
    return;
  }

  final request = await context
      .read<services.ServiceProvider>()
      .fetchServiceRequest(requestId);
  if (!context.mounted) return;

  final currentUser = context.read<AuthViewModel>().currentUser;
  if (request == null || currentUser == null) {
    await _openServicesBrowse(context);
    return;
  }

  final opensProviderView =
      notification.type == AppConstants.notificationTypeServiceRequest ||
      notification.type ==
          AppConstants.notificationTypeServicePaymentReceived ||
      notification.type ==
          AppConstants.notificationTypeServiceArrivalVerified ||
      notification.type == AppConstants.notificationTypeServicePayoutSent ||
      notification.type == AppConstants.notificationTypeServicePayoutFailed ||
      (notification.type == AppConstants.notificationTypeServiceDisputed &&
          currentUser.uid == request.providerId) ||
      (notification.type == AppConstants.notificationTypeServiceAdminResolved &&
          currentUser.uid == request.providerId);

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => ServiceTransactionView(
        initialRequest: request,
        user: currentUser,
        requesterView: !opensProviderView,
      ),
    ),
  );
}

/// Marketplace notifications: opens borrower transaction view or lender request detail based on notification type and user role.
Future<void> _openBorrowNotification(
  BuildContext context,
  NotificationModel notification,
) async {
  final requestId = notification.borrowRequestId.trim();
  if (requestId.isEmpty) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ResidentMarketplaceView(),
      ),
    );
    return;
  }

  final request = await context
      .read<BorrowRequestProvider>()
      .fetchBorrowRequest(requestId);
  if (!context.mounted) return;

  if (request == null) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ResidentMarketplaceView(),
      ),
    );
    return;
  }

  final currentUser = context.read<AuthViewModel>().currentUser;
  // Marketplace deposit notifications: payout events and lender-side deposit decisions must open the lender detail screen.
  final opensLenderDetail =
      notification.type == AppConstants.notificationTypeBorrowRequest ||
      notification.type == AppConstants.notificationTypeBorrowPayoutReady ||
      notification.type == AppConstants.notificationTypeBorrowPayoutPaid ||
      (notification.type == AppConstants.notificationTypeBorrowDepositResolved &&
          currentUser?.uid == request.ownerId);

  if (opensLenderDetail) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ResidentLenderRequestDetailView(initialRequest: request),
      ),
    );
    return;
  }

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => MarketplaceTransactionView(initialRequest: request),
    ),
  );
}

/// Neighbor activity notifications: opens a connected neighbor's marketplace listing when possible.
Future<void> _openNeighborItemNotification(
  BuildContext context,
  NotificationModel notification,
) async {
  final itemId = notification.itemId.trim();
  if (itemId.isEmpty) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ResidentMarketplaceView(),
      ),
    );
    return;
  }

  final item = await ItemRepository().getItemById(itemId);
  if (!context.mounted) return;

  if (item == null) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ResidentMarketplaceView(),
      ),
    );
    return;
  }

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => MarketplaceItemDetailView(item: item),
    ),
  );
}

/// Neighbor activity notifications: opens a connected neighbor's service listing when possible.
Future<void> _openNeighborServiceNotification(
  BuildContext context,
  NotificationModel notification,
) async {
  final serviceId = notification.serviceId.trim();
  if (serviceId.isEmpty) {
    await _openServicesBrowse(context);
    return;
  }

  final service = await context
      .read<services.ServiceProvider>()
      .getService(serviceId);
  if (!context.mounted) return;

  final currentUser = context.read<AuthViewModel>().currentUser;
  if (service == null || currentUser == null) {
    await _openServicesBrowse(context);
    return;
  }

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => ServiceDetailView(
        user: currentUser,
        service: service,
      ),
    ),
  );
}

/// Services notifications: opens the browse screen when a service deep link is unavailable.
Future<void> _openServicesBrowse(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const ResidentServicesView(),
    ),
  );
}

/// Community notifications: opens a specific community post when the notification includes a post id.
Future<void> _openCommunityNotification(
  BuildContext context,
  NotificationModel notification,
) async {
  final postId = notification.postId.trim();
  if (postId.isNotEmpty) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CommunityPostDetailView(postId: postId),
      ),
    );
    return;
  }

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const ResidentHomeView(),
    ),
  );
}

/// Notifications feature: fallback destination when a notification cannot be deep-linked safely.
Future<void> _openNotificationsInbox(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const ResidentNotificationsView(),
    ),
  );
}
