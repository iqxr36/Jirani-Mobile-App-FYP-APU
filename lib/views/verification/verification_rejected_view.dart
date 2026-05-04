import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/views/verification/upload_verification_document_view.dart';

class VerificationRejectedView extends StatelessWidget {
  const VerificationRejectedView({
    super.key,
    required this.rejectionReason,
  });

  final String? rejectionReason;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification rejected')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.cancel_outlined, size: 64, color: Colors.red.shade700),
              const SizedBox(height: 16),
              Text(
                'Could not verify residency',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (rejectionReason != null && rejectionReason!.trim().isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reason', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Text(rejectionReason!, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  'Please review your documents and try again, or contact management if you need help.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const UploadVerificationDocumentView(),
                    ),
                  );
                },
                child: const Text('Resubmit Document'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
