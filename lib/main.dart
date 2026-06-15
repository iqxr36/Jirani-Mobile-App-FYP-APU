import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/theme/app_theme.dart';
import 'package:jirani/providers/auth_provider.dart';
import 'package:jirani/providers/chat_provider.dart';
import 'package:jirani/providers/connection_provider.dart';
import 'package:jirani/screens/auth/auth_wrapper.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) {
    return MaterialApp(
      title: '${AppConstants.appName} render error',
      theme: AppTheme.lightTheme,
      home: StartupErrorScaffold(error: details.exceptionAsString()),
    );
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kIsWeb) {
      // DEVELOPMENT / TESTING ONLY
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidDebugProvider(),
        providerApple: const AppleDebugProvider(),
      );

      // PRODUCTION ONLY - enable this before release
      // await FirebaseAppCheck.instance.activate(
      //   providerAndroid: const AndroidPlayIntegrityProvider(),
      //   providerApple: const AppleDeviceCheckProvider(),
      // );
    }
    runApp(const TrustCommunityApp());
  } catch (e, stackTrace) {
    debugPrint('Firebase startup failed: $e');
    debugPrintStack(stackTrace: stackTrace);
    runApp(StartupErrorApp(error: e.toString()));
  }
}

class TrustCommunityApp extends StatelessWidget {
  const TrustCommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
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
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return JiraniBackground(child: child ?? const SizedBox.shrink());
        },
        home: const AuthWrapper(),
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
      body: Center(
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
                    'Admin portal could not start',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A startup or rendering error stopped the web admin portal from loading.',
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
    );
  }
}
