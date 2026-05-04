import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/widgets/verified_badge.dart';

class VerificationApprovedView extends StatelessWidget {
  const VerificationApprovedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verified')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.celebration_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              const Center(child: VerifiedBadge()),
              const SizedBox(height: 16),
              Text(
                'You are a verified resident',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Community features will unlock as they become available in upcoming phases.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Continue to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
