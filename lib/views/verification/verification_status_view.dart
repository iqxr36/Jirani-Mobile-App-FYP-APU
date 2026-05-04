import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/viewmodels/verification_viewmodel.dart';
import 'package:fyp_flutter_application/views/location/location_permission_view.dart';
import 'package:fyp_flutter_application/views/verification/verification_approved_view.dart';
import 'package:fyp_flutter_application/views/verification/verification_cancel_dialog.dart';
import 'package:fyp_flutter_application/views/verification/verification_pending_view.dart';
import 'package:fyp_flutter_application/views/verification/verification_rejected_view.dart';
import 'package:fyp_flutter_application/widgets/verification_status_chip.dart';
import 'package:fyp_flutter_application/widgets/verified_badge.dart';
import 'package:provider/provider.dart';

/// Summary of residency verification for the current user.
class VerificationStatusView extends StatefulWidget {
  const VerificationStatusView({super.key});

  @override
  State<VerificationStatusView> createState() => _VerificationStatusViewState();
}

class _VerificationStatusViewState extends State<VerificationStatusView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VerificationViewModel>().loadCurrentRequest();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final verificationVm = context.watch<VerificationViewModel>();
    final user = authVm.currentUser;
    final request = verificationVm.currentRequest;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verification')),
        body: const Center(child: Text('Sign in to view verification status.')),
      );
    }

    final status = user.verificationStatus;

    return Scaffold(
      appBar: AppBar(title: const Text('Verification status')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account status', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          VerificationStatusChip(status: status),
                          if (user.isVerifiedResident) ...[
                            const SizedBox(width: 8),
                            const VerifiedBadge(compact: true),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (verificationVm.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (verificationVm.errorMessage != null)
                Text(verificationVm.errorMessage!, style: const TextStyle(color: Colors.red))
              else if (request != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Latest request', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        _DetailRow(label: 'Submitted', value: _formatDate(request.submittedAt)),
                        _DetailRow(label: 'Document type', value: request.documentType),
                        _DetailRow(label: 'Community', value: request.communityName),
                        _DetailRow(label: 'Unit', value: request.unitNumber),
                        if (request.notes.isNotEmpty) _DetailRow(label: 'Notes', value: request.notes),
                        if (request.rejectionReason != null && request.rejectionReason!.isNotEmpty)
                          _DetailRow(label: 'Rejection reason', value: request.rejectionReason!),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (status == AppConstants.verificationPending) ...[
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const LocationPermissionView()),
                    );
                  },
                  child: const Text('Start verification'),
                ),
              ] else if (status == AppConstants.verificationSubmitted) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const VerificationPendingView()),
                        );
                      },
                      child: const Text('View pending details'),
                    ),
                    if (_requestStatusIsCancellable(request?.status)) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: verificationVm.isLoading
                            ? null
                            : () => executeVerificationCancellation(context),
                        child: const Text('Cancel Submission'),
                      ),
                    ],
                  ],
                ),
              ] else if (status == AppConstants.verificationRejected) ...[
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => VerificationRejectedView(
                          rejectionReason: request?.rejectionReason,
                        ),
                      ),
                    );
                  },
                  child: const Text('Resubmit verification'),
                ),
              ] else if (status == AppConstants.verificationVerified) ...[
                FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const VerificationApprovedView()),
                    );
                  },
                  child: const Text('View verified confirmation'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static bool _requestStatusIsCancellable(String? requestStatus) {
    if (requestStatus == null) return false;
    return requestStatus == AppConstants.verificationSubmitted ||
        requestStatus == AppConstants.verificationRequestPending;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
