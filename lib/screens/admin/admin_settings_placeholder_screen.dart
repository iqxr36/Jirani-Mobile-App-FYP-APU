import 'package:flutter/material.dart';

class AdminSettingsPlaceholderScreen extends StatelessWidget {
  const AdminSettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Settings')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Admin settings and configuration will be implemented in a later phase.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
