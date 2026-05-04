import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/viewmodels/verification_viewmodel.dart';
import 'package:fyp_flutter_application/views/verification/verification_cancel_dialog.dart';
import 'package:provider/provider.dart';

/// Shown after the resident submits documents for review.
class VerificationPendingView extends StatefulWidget {
  const VerificationPendingView({super.key});

  @override
  State<VerificationPendingView> createState() => _VerificationPendingViewState();
}

class _VerificationPendingViewState extends State<VerificationPendingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VerificationViewModel>().loadCurrentRequest();
    });
  }

  static bool _requestStatusIsCancellable(String? requestStatus) {
    if (requestStatus == null) return false;
    return requestStatus == AppConstants.verificationSubmitted ||
        requestStatus == AppConstants.verificationRequestPending;
  }

  @override
  Widget build(BuildContext context) {
    final verificationVm = context.watch<VerificationViewModel>();
    final request = verificationVm.currentRequest;

    return Scaffold(
      appBar: AppBar(title: const Text('Verification submitted')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.hourglass_top_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Under review',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your residency verification has been submitted. Full marketplace, services, and chat access '
                'will unlock after verification.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              if (_requestStatusIsCancellable(request?.status)) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: verificationVm.isLoading ? null : () => executeVerificationCancellation(context),
                  child: const Text('Cancel Submission'),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                onPressed: verificationVm.isLoading
                    ? null
                    : () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
