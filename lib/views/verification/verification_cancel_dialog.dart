import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/viewmodels/verification_viewmodel.dart';
import 'package:provider/provider.dart';

Future<bool> showVerificationCancelConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Cancel verification submission?'),
        content: const Text(
          'Your current verification request will be marked as cancelled. '
          'You can submit a new request after this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Request'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Submission'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Confirms with the user, cancels the latest request, refreshes profile and VM, shows feedback, returns to root.
Future<void> executeVerificationCancellation(BuildContext context) async {
  final authVm = context.read<AuthViewModel>();
  final verificationVm = context.read<VerificationViewModel>();
  final confirmed = await showVerificationCancelConfirmationDialog(context);
  if (!context.mounted) return;
  if (!confirmed) return;

  final ok = await verificationVm.cancelLatestVerificationRequest();
  if (!context.mounted) return;

  if (ok) {
    await authVm.refreshCurrentUser();
    await verificationVm.loadCurrentRequest();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification submission cancelled. You can submit a new request.'),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  } else {
    final msg = verificationVm.errorMessage;
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}
