import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/theme/app_theme.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/shared/providers/auth_provider.dart';
import 'package:jirani/resident/providers/borrow_request_provider.dart';
import 'package:jirani/resident/providers/chat_provider.dart';
import 'package:jirani/resident/providers/connection_provider.dart';
import 'package:jirani/resident/providers/item_provider.dart';
import 'package:jirani/resident/providers/notification_provider.dart';
import 'package:jirani/resident/providers/network_status_provider.dart';
import 'package:jirani/resident/providers/payment_provider.dart';
import 'package:jirani/resident/providers/review_provider.dart';
import 'package:jirani/resident/providers/theme_provider.dart';
import 'package:jirani/shared/logic/auth_wrapper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:jirani/shared/services/internet_connectivity_checker.dart';
import 'package:jirani/shared/services/push_notification_service.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:jirani/shared/widgets/network_status_overlay.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final PushNotificationService pushNotificationService = PushNotificationService();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) {
    return MaterialApp(
      title: '${AppConstants.appName} render error',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StartupErrorScaffold(error: details.exceptionAsString()),
    );
  };

  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  _BootstrapPhase _phase = _BootstrapPhase.initializing;
  String? _error;
  bool _isRetrying = false;
  bool? _hasInternet;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (kIsWeb) {
      await _initialize();
      return;
    }

    final online = InternetConnectivityChecker.hasNetworkInterface(
      await Connectivity().checkConnectivity(),
    );
    if (!mounted) return;

    if (online) {
      setState(() => _hasInternet = true);
      await _initialize();
      return;
    }

    setState(() => _hasInternet = false);
    _listenForReconnect();
  }

  void _listenForReconnect() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (!InternetConnectivityChecker.hasNetworkInterface(results)) return;
      unawaited(_retryFromGate());
    });
  }

  Future<void> _retryFromGate() async {
    if (_isRetrying || _phase == _BootstrapPhase.ready) return;

    setState(() => _isRetrying = true);
    final online = InternetConnectivityChecker.hasNetworkInterface(
      await Connectivity().checkConnectivity(),
    );
    if (!mounted) return;

    if (!online) {
      setState(() => _isRetrying = false);
      return;
    }

    _connectivitySubscription?.cancel();
    setState(() => _hasInternet = true);
    await _initialize();
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() => _isRetrying = true);
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (!kIsWeb) {
        await _activateFirebaseAppCheck();
      }
      await _configureStripe();
      if (!kIsWeb) {
        await pushNotificationService.initialize(navigatorKey: appNavigatorKey);
      }
      if (!mounted) return;
      setState(() {
        _phase = _BootstrapPhase.ready;
        _isRetrying = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Firebase startup failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _phase = _BootstrapPhase.error;
        _error = e.toString();
        _isRetrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _BootstrapPhase.error:
        return StartupErrorApp(error: _error ?? 'Unknown startup error');
      case _BootstrapPhase.ready:
        return const TrustCommunityApp();
      case _BootstrapPhase.initializing:
        if (kIsWeb) {
          return _bootstrapMaterialApp(
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (_hasInternet == false) {
          return _bootstrapMaterialApp(
            home: ConnectivityGateScreen(
              isRefreshing: _isRetrying,
              onRefresh: _retryFromGate,
            ),
          );
        }
        return _bootstrapMaterialApp(home: const _BootstrapLoadingScreen());
    }
  }

  Widget _bootstrapMaterialApp({required Widget home}) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: home,
    );
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const JiraniBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

enum _BootstrapPhase { initializing, ready, error }

Future<void> _activateFirebaseAppCheck() async {
  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
      providerApple: const AppleDebugProvider(),
    );
    return;
  }

  await FirebaseAppCheck.instance.activate(
    providerAndroid: const AndroidPlayIntegrityProvider(),
    providerApple: const AppleDeviceCheckProvider(),
  );
}

Future<void> _configureStripe() async {
  const publishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  if (publishableKey.trim().isEmpty) {
    debugPrint('Stripe publishable key not configured.');
    return;
  }
  Stripe.publishableKey = publishableKey;
  await Stripe.instance.applySettings();
}

class TrustCommunityApp extends StatelessWidget {
  const TrustCommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ItemProvider>(create: (_) => ItemProvider()),
        ChangeNotifierProvider<BorrowRequestProvider>(
          create: (_) => BorrowRequestProvider(),
        ),
        ChangeNotifierProvider<ReviewProvider>(create: (_) => ReviewProvider()),
        ChangeNotifierProvider<PaymentProvider>(
          create: (_) => PaymentProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        if (!kIsWeb)
          ChangeNotifierProvider<NetworkStatusProvider>(
            create: (_) => NetworkStatusProvider(),
          ),
        ChangeNotifierProxyProvider<AuthProvider, ConnectionProvider>(
          create: (_) => ConnectionProvider(),
          update: (_, auth, provider) {
            final connectionProvider = provider ?? ConnectionProvider();
            connectionProvider.watchForUser(auth.currentUser);
            return connectionProvider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, auth, provider) {
            final chatProvider = provider ?? ChatProvider();
            chatProvider.watchForUser(auth.currentUser);
            return chatProvider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, auth, provider) {
            final notificationProvider = provider ?? NotificationProvider();
            notificationProvider.watchForUser(auth.currentUser);
            return notificationProvider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            navigatorKey: appNavigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              final appBody = JiraniBackground(
                child: child ?? const SizedBox.shrink(),
              );
              return MediaQuery(
                data: media.copyWith(
                  textScaler: JiraniResponsive.clampedTextScaler(context),
                ),
                child: kIsWeb ? appBody : NetworkStatusOverlay(child: appBody),
              );
            },
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${AppConstants.appName} startup error',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StartupErrorScaffold(error: error),
    );
  }
}

class StartupErrorScaffold extends StatelessWidget {
  const StartupErrorScaffold({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFE29578),
                        size: 42,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${AppConstants.appName} could not load',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A startup or rendering error stopped this screen from loading.',
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        error,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
