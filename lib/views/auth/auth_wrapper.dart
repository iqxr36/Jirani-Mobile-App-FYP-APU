import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/views/auth/login_view.dart';
import 'package:fyp_flutter_application/views/auth/account_created_view.dart';
import 'package:fyp_flutter_application/views/home/resident_home_placeholder_view.dart';
import 'package:provider/provider.dart';

/// Routes the app based on [FirebaseAuth] session and loaded [AppUser] profile.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        if (!vm.isAuthBootstrapComplete) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.firebaseUser == null) {
          return const LoginView();
        }

        if (vm.isProfileLoading) {
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

        if (vm.showAccountCreatedScreen) {
          return const AccountCreatedView();
        }

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
