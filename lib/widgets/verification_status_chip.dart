import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';

class VerificationStatusChip extends StatelessWidget {
  const VerificationStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(status);
    final color = _colorFor(context, status);

    return Chip(
      avatar: Icon(_iconFor(status), size: 18, color: color),
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  static String _labelFor(String status) {
    switch (status) {
      case AppConstants.verificationPending:
        return 'Pending';
      case AppConstants.verificationSubmitted:
        return 'Submitted';
      case AppConstants.verificationVerified:
        return 'Verified';
      case AppConstants.verificationRejected:
        return 'Rejected';
      default:
        return status.isEmpty ? 'Unknown' : status;
    }
  }

  static Color _colorFor(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case AppConstants.verificationPending:
        return Colors.grey.shade700;
      case AppConstants.verificationSubmitted:
        return Colors.orange.shade800;
      case AppConstants.verificationVerified:
        return scheme.primary;
      case AppConstants.verificationRejected:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  static IconData _iconFor(String status) {
    switch (status) {
      case AppConstants.verificationPending:
        return Icons.schedule_outlined;
      case AppConstants.verificationSubmitted:
        return Icons.hourglass_top_outlined;
      case AppConstants.verificationVerified:
        return Icons.verified_outlined;
      case AppConstants.verificationRejected:
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
