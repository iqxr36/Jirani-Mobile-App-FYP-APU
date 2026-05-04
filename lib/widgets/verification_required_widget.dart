import 'package:flutter/material.dart';

class VerificationRequiredWidget extends StatelessWidget {
  const VerificationRequiredWidget({
    super.key,
    required this.onActionPressed,
  });

  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Verification required',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete residency verification to access marketplace features.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onActionPressed,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('View Verification Status'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
