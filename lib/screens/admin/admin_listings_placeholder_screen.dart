import 'package:flutter/material.dart';

class AdminListingsPlaceholderScreen extends StatelessWidget {
  const AdminListingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listings Moderation')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Marketplace listing moderation will be implemented in a later phase.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
