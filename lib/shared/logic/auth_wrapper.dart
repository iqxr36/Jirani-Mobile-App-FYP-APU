import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:jirani/core/utils/auth_debug_log.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/admin/screens/admin_dashboard_screen.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/resident/screens/home/resident_main_shell.dart';
import 'package:jirani/admin/screens/auth/admin_login_screen.dart';
import 'package:jirani/resident/screens/auth/email_verification_view.dart';
import 'package:jirani/resident/screens/auth/phone_verification_view.dart';
import 'package:jirani/resident/screens/auth/resident_pre_auth_gate.dart';
import 'package:jirani/resident/screens/auth/account_created_view.dart';
import 'package:provider/provider.dart';
import 'package:jirani/resident/screens/location/resident_geofence_gate.dart';

/// Routes the app based on [FirebaseAuth] session and loaded [AppUser] profile.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        authDebugLog('[AuthWrapper] build start kIsWeb=$kIsWeb');
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
          if (kIsWeb) {
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

        if (vm.currentUser == null && vm.currentAdmin == null) {
          return _MissingProfileScaffold(
            message:
                vm.profileErrorMessage ??
                'Your account profile could not be loaded.',
            onLogout: () => context.read<AuthViewModel>().logout(),
            isLoggingOut: vm.isLoading,
          );
        }

        final user = vm.currentUser;
        final admin = vm.currentAdmin;
        final role = user?.role ?? admin?.role ?? '';
        final isAdmin = admin != null;
        if (role != AppConstants.roleResident && !isAdmin) {
          return _MissingProfileScaffold(
            message: 'Unknown role "$role". Please contact support.',
            onLogout: () => context.read<AuthViewModel>().logout(),
            isLoggingOut: vm.isLoading,
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

        if (vm.showPhoneVerificationAfterRegister && user != null) {
          authDebugLog('[AuthWrapper] route -> PhoneVerificationView');
          final phone = user.phoneNumber.trim();
          return PhoneVerificationView(
            phoneNumber: phone,
            verificationId: null,
            resendToken: null,
            onFlowFinished: () => context
                .read<AuthViewModel>()
                .exitPhoneVerificationRegistrationFlow(),
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

        if (!kIsWeb) {
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
