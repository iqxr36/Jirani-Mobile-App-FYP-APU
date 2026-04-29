import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to ${AppConstants.appName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Logged in as: ${user?.email ?? 'Unknown user'}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: authViewModel.isLoading
                  ? null
                  : () async {
                      await context.read<AuthViewModel>().logout();
                    },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
