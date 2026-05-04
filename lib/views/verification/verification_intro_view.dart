import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/views/verification/upload_verification_document_view.dart';

class VerificationIntroView extends StatelessWidget {
  const VerificationIntroView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your residency')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.verified_user_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Follow these steps to unlock your verified resident badge.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade800),
              ),
              const SizedBox(height: 20),
              _StepTile(number: 1, text: 'Upload proof of residence'),
              _StepTile(number: 2, text: 'System stores your document securely'),
              _StepTile(number: 3, text: 'Management reviews if needed'),
              _StepTile(number: 4, text: 'Verified badge unlocked'),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const UploadVerificationDocumentView(),
                    ),
                  );
                },
                child: const Text('Start Verification'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              '$number',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(text),
        ),
      ),
    );
  }
}
