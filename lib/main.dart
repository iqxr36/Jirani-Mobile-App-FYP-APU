import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/core/theme/app_theme.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/views/auth/login_view.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TrustCommunityApp());
}

class TrustCommunityApp extends StatelessWidget {
  const TrustCommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        home: const LoginView(),
      ),
    );
  }
}
