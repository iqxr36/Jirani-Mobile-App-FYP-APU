import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jirani/resident/screens/notifications/resident_notifications_view.dart';
import 'package:jirani/shared/data/repositories/verification_permission_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are surfaced by the OS notification payload.
}

class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    VerificationPermissionRepository? permissionRepository,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _permissionRepository =
           permissionRepository ?? VerificationPermissionRepository(),
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final VerificationPermissionRepository _permissionRepository;
  final FlutterLocalNotificationsPlugin _localNotifications;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'jirani_default',
        'Jirani notifications',
        description: 'Residence updates, messages, and community activity',
        importance: Importance.high,
      );

  StreamSubscription<String>? _tokenRefreshSub;
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;

  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_initialized || kIsWeb) return;
    _navigatorKey = navigatorKey;
    _initialized = true;

    await _configureLocalNotifications();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final authorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (authorized) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _permissionRepository.saveFcmToken(token);
      }
    }

    _tokenRefreshSub = _messaging.onTokenRefresh.listen(
      _permissionRepository.saveFcmToken,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedMessage(initialMessage);
    }
  }

  Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (_) {},
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'jirani_default',
      'Jirani notifications',
      channelDescription:
          'Residence updates, messages, and community activity',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ResidentNotificationsView(),
      ),
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
  }
}
