import 'package:flutter/material.dart';

class AdminUsersPlaceholderScreen extends StatelessWidget {
  const AdminUsersPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users Management')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'User suspension, role management, and resident monitoring will be implemented in a later phase.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
