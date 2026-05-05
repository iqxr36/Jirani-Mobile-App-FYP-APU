import 'package:flutter/material.dart';

class AdminReportsPlaceholderScreen extends StatelessWidget {
  const AdminReportsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Safety')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Report review and moderation will be implemented in a later phase.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
