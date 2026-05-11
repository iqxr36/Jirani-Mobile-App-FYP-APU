import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/admin/screens/auth/admin_login_screen.dart';
import 'package:fyp_flutter_application/admin/screens/dashboard/admin_dashboard_screen.dart';
import 'package:fyp_flutter_application/views/auth/phone_verification_view.dart';
import 'package:fyp_flutter_application/views/auth/resident_pre_auth_gate.dart';
import 'package:fyp_flutter_application/resident/screens/auth/account_created_view.dart';
import 'package:fyp_flutter_application/resident/screens/home/resident_home_placeholder_view.dart';
import 'package:provider/provider.dart';

/// Routes the app based on [FirebaseAuth] session and loaded [AppUser] profile.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        debugPrint('[AuthWrapper] build start kIsWeb=$kIsWeb');
        debugPrint(
          '[AuthWrapper] firebaseUser=${vm.firebaseUser?.uid} currentUser=${vm.currentUser?.uid} role=${vm.currentUser?.role} '
          'isAuthBootstrapComplete=${vm.isAuthBootstrapComplete} isProfileLoading=${vm.isProfileLoading}',
        );
        if (!vm.isAuthBootstrapComplete) {
          debugPrint('[AuthWrapper] route -> bootstrap loading');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.firebaseUser == null) {
          if (kIsWeb) {
            debugPrint('[AuthWrapper] route -> AdminLoginScreen');
            return const AdminLoginScreen();
          }
          debugPrint('[AuthWrapper] route -> Resident pre-auth (onboarding or login)');
          return const ResidentPreAuthGate();
        }

        if (vm.isProfileLoading) {
          debugPrint('[AuthWrapper] route -> profile loading');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.currentUser == null) {
          return _MissingProfileScaffold(
            message: vm.profileErrorMessage ?? 'Your account profile could not be loaded.',
            onLogout: () => context.read<AuthViewModel>().logout(),
            isLoggingOut: vm.isLoading,
          );
        }

        final role = vm.currentUser!.role;
        if (role == AppConstants.roleCommunityAdmin || role == AppConstants.roleSystemAdmin) {
          debugPrint('[AuthWrapper] route -> AdminDashboardScreen');
          return const AdminDashboardScreen();
        }
        if (kIsWeb && role == AppConstants.roleResident) {
          debugPrint('[AuthWrapper] route -> web resident blocked');
          return _MissingProfileScaffold(
            message: 'This account does not have admin access.',
            onLogout: () => context.read<AuthViewModel>().logout(),
            isLoggingOut: vm.isLoading,
          );
        }
        if (role != AppConstants.roleResident) {
          return _MissingProfileScaffold(
            message: 'Unknown role "$role". Please contact support.',
            onLogout: () => context.read<AuthViewModel>().logout(),
            isLoggingOut: vm.isLoading,
          );
        }

        if (vm.showPhoneVerificationAfterRegister && vm.currentUser != null) {
          debugPrint('[AuthWrapper] route -> PhoneVerificationView');
          final phone = vm.currentUser!.phoneNumber.trim();
          return PhoneVerificationView(
            phoneNumber: phone,
            verificationId: null,
            resendToken: null,
            onFlowFinished: () => context.read<AuthViewModel>().exitPhoneVerificationRegistrationFlow(),
          );
        }

        if (vm.showAccountCreatedScreen) {
          debugPrint('[AuthWrapper] route -> AccountCreatedView');
          return const AccountCreatedView();
        }

        debugPrint('[AuthWrapper] route -> ResidentHomePlaceholderView');
        return const ResidentHomePlaceholderView();
      },
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
            const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
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
