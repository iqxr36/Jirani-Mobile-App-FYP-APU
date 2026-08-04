// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : auth_wrapper.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:jirani/core/utils/auth_debug_log.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/admin/screens/admin_dashboard_screen.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/resident/screens/home/resident_main_shell.dart';
import 'package:jirani/admin/screens/auth/admin_login_screen.dart';
import 'package:jirani/resident/screens/auth/email_verification_view.dart';
import 'package:jirani/resident/screens/auth/resident_pre_auth_gate.dart';
import 'package:jirani/resident/screens/auth/account_created_view.dart';
import 'package:jirani/resident/screens/auth/google_registration_completion_view.dart';
import 'package:jirani/resident/screens/auth/suspended_account_view.dart';
import 'package:provider/provider.dart';
import 'package:jirani/resident/screens/location/resident_geofence_gate.dart';

/// Routes the app based on [FirebaseAuth] session and loaded [AppUser] profile.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({
    super.key,
    @visibleForTesting this.isWebOverride,
    @visibleForTesting this.googleRegistrationBuilder,
  });

  /// Allows widget tests to exercise web-only routing without launching Chrome.
  final bool? isWebOverride;
  final WidgetBuilder? googleRegistrationBuilder;

  @override
  /// [Authentication Rank 1 — MAIN] Routes the session to resident onboarding, protected mobile content, or the admin portal.
  Widget build(BuildContext context) {
    final isWeb = isWebOverride ?? kIsWeb;
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        authDebugLog('[AuthWrapper] build start kIsWeb=$isWeb');
        authDebugLog(
          '[AuthWrapper] firebaseUser=${vm.firebaseUser != null} '
          'currentUser=${vm.currentUser != null} '
          'currentAdmin=${vm.currentAdmin != null} '
          'isAuthBootstrapComplete=${vm.isAuthBootstrapComplete} '
          'isProfileLoading=${vm.isProfileLoading}',
        );
        if (!vm.isAuthBootstrapComplete) {
          authDebugLog('[AuthWrapper] route -> bootstrap loading');
          return const _AuthLoadingScaffold();
        }

        if (vm.firebaseUser == null) {
          if (isWeb) {
            authDebugLog('[AuthWrapper] route -> AdminLoginScreen');
            return const AdminLoginScreen();
          }
          authDebugLog(
            '[AuthWrapper] route -> Resident pre-auth (onboarding or login)',
          );
          return const ResidentPreAuthGate();
        }

        if (vm.isProfileLoading) {
          authDebugLog('[AuthWrapper] route -> profile loading');
          return const _AuthLoadingScaffold();
        }

        final user = vm.currentUser;
        final admin = vm.currentAdmin;

        // The web build is the administrator portal. Keep the login screen in
        // place while a non-admin session is rejected so it can never route to
        // resident features or the admin dashboard.
        if (isWeb && admin == null) {
          authDebugLog(
            '[AuthWrapper] route -> AdminLoginScreen (non-admin blocked)',
          );
          return const AdminLoginScreen();
        }

        if (!isWeb && vm.needsGoogleRegistration) {
          authDebugLog(
            '[AuthWrapper] route -> GoogleRegistrationCompletionView',
          );
          return googleRegistrationBuilder?.call(context) ??
              const GoogleRegistrationCompletionView();
        }

        if (user == null && admin == null) {
          return _MissingProfileScaffold(
            message:
                vm.profileErrorMessage ??
                'Your account profile could not be loaded.',
            onLogout: () => context.read<AuthViewModel>().logout(),
            isLoggingOut: vm.isLoading,
          );
        }

        final role = user?.role ?? admin?.role ?? '';
        final isAdmin = admin != null;
        if (role != AppConstants.roleResident && !isAdmin) {
          return _MissingProfileScaffold(
            message: 'Unknown role "$role". Please contact support.',
            onLogout: () => context.read<AuthViewModel>().logout(),
            isLoggingOut: vm.isLoading,
          );
        }

        if (user?.hasActiveSuspension ?? false) {
          authDebugLog('[AuthWrapper] route -> SuspendedAccountView');
          return SuspendedAccountView(
            user: user!,
            onCheckStatus: () =>
                context.read<AuthViewModel>().refreshCurrentUser(),
            onSignOut: () => context.read<AuthViewModel>().logout(),
          );
        }

        if (vm.showEmailVerificationAfterRegister && user != null) {
          authDebugLog('[AuthWrapper] route -> EmailVerificationView');
          return EmailVerificationView(
            email: user.email,
            onVerified: () => context
                .read<AuthViewModel>()
                .exitEmailVerificationRegistrationFlow(),
            onSkip: () => context
                .read<AuthViewModel>()
                .skipEmailVerificationRegistrationFlow(),
          );
        }

        if (vm.showAccountCreatedScreen) {
          authDebugLog('[AuthWrapper] route -> AccountCreatedView');
          return const AccountCreatedView();
        }

        if (user?.role == AppConstants.roleResident) {
          authDebugLog('[AuthWrapper] route -> ResidentMainShell (home)');
          return ResidentGeofenceGate(
            user: user!,
            child: const ResidentMainShell(),
          );
        }

        if (!isWeb) {
          authDebugLog('[AuthWrapper] route -> mobile admin blocked');
          return _MobileAdminBlockedScaffold(
            onRetry: () => context.read<AuthViewModel>().refreshCurrentUser(),
            onLogout: () => context.read<AuthViewModel>().logout(),
            isLoggingOut: vm.isLoading,
          );
        }

        authDebugLog('[AuthWrapper] route -> AdminDashboardScreen');
        return AdminDashboardScreen(
          onLogout: () => context.read<AuthViewModel>().logout(),
          isLoggingOut: vm.isLoading,
        );
      },
    );
  }
}

/// Auth routing UI: shown while Firebase session or Firestore profile bootstrapping is still loading.
class _AuthLoadingScaffold extends StatelessWidget {
  const _AuthLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Auth routing UI: blocks admin accounts from using the mobile resident app.
class _MobileAdminBlockedScaffold extends StatelessWidget {
  const _MobileAdminBlockedScaffold({
    required this.onRetry,
    required this.onLogout,
    required this.isLoggingOut,
  });

  final VoidCallback onRetry;
  final VoidCallback onLogout;
  final bool isLoggingOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Admin access')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.computer_rounded,
              size: 48,
              color: Color(0xFF006D77),
            ),
            const SizedBox(height: 16),
            Text(
              'Admin access is available on the web portal only.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Use the Jirani mobile app with a resident account, or sign in as an admin from a browser.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
            const Spacer(),
            FilledButton(
              onPressed: isLoggingOut ? null : onRetry,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: isLoggingOut ? null : onLogout,
              child: isLoggingOut
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Auth routing UI: explains when Firebase Auth exists but the required Firestore profile is missing.
class _MissingProfileScaffold extends StatelessWidget {
  const _MissingProfileScaffold({
    required this.message,
    required this.onLogout,
    required this.isLoggingOut,
  });

  final String message;
  final VoidCallback onLogout;
  final bool isLoggingOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'If you just registered, try again in a moment. Otherwise contact support.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
            const Spacer(),
            FilledButton(
              onPressed: isLoggingOut ? null : onLogout,
              child: isLoggingOut
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
