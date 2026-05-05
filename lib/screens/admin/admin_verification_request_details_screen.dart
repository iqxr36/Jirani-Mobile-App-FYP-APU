import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/providers/admin_provider.dart';
import 'package:fyp_flutter_application/providers/auth_provider.dart';
import 'package:fyp_flutter_application/screens/admin/admin_unauthorized_screen.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_document_preview.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_section_card.dart';
import 'package:provider/provider.dart';

class AdminVerificationRequestDetailsScreen extends StatefulWidget {
  const AdminVerificationRequestDetailsScreen({super.key, required this.requestId});
  final String requestId;

  @override
  State<AdminVerificationRequestDetailsScreen> createState() => _AdminVerificationRequestDetailsScreenState();
}

class _AdminVerificationRequestDetailsScreenState extends State<AdminVerificationRequestDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadVerificationRequestById(widget.requestId);
    });
  }

  Future<void> _approve() async {
    final auth = context.read<AuthProvider>();
    final vm = context.read<AdminProvider>();
    final req = vm.selectedRequest;
    final adminUid = auth.currentUser?.uid;
    if (req == null || adminUid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve this resident?'),
        content: const Text(
          'This will mark the resident as verified and unlock full community features.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Approve')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await vm.approveRequest(request: req, adminUid: adminUid);
    if (!mounted) return;
    if (vm.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resident verified successfully')));
      Navigator.of(context).pop();
    }
  }

  Future<void> _reject() async {
    final auth = context.read<AuthProvider>();
    final vm = context.read<AdminProvider>();
    final req = vm.selectedRequest;
    final adminUid = auth.currentUser?.uid;
    if (req == null || adminUid == null) return;

    String reason = '';
    final controller = TextEditingController();
    final rejected = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Reject request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _reasonChip('Document unclear', controller, setStateDialog),
                  _reasonChip('Wrong unit number', controller, setStateDialog),
                  _reasonChip('Document does not match resident', controller, setStateDialog),
                  _reasonChip('Expired or invalid document', controller, setStateDialog),
                  _reasonChip('Other', controller, setStateDialog),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Rejection reason',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => reason = v,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                reason = controller.text.trim();
                if (reason.isEmpty) return;
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || rejected != true) return;
    reason = controller.text.trim();
    controller.dispose();
    if (reason.isEmpty) return;

    await vm.rejectRequest(request: req, adminUid: adminUid, rejectionReason: reason);
    if (!mounted) return;
    if (vm.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification request rejected')));
      Navigator.of(context).pop();
    }
  }

  Widget _reasonChip(
    String label,
    TextEditingController controller,
    void Function(void Function()) setStateDialog,
  ) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        controller.text = label;
        setStateDialog(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final vm = context.watch<AdminProvider>();
    final user = auth.currentUser;
    if (user == null || !user.isAdmin) {
      return const AdminUnauthorizedScreen();
    }
    final req = vm.selectedRequest;

    return Scaffold(
      appBar: AppBar(title: const Text('Verification Request Details')),
      body: req == null
          ? Center(
              child: vm.isLoading
                  ? const CircularProgressIndicator()
                  : Text(vm.errorMessage ?? 'Request not found.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AdminSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resident Information', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _kv('Full name', req.fullName),
                      _kv('Email', req.email),
                      _kv('Phone number', req.phoneNumber),
                      _kv('User ID', req.userId),
                      _kv('Current status', req.status),
                      _kv('Submitted date', _fmt(req.submittedAt)),
                    ],
                  ),
                ),
                AdminSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Residence Information', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _kv('Community/building', req.communityName),
                      _kv('Unit', req.unitNumber),
                      _kv('Notes', req.notes.isEmpty ? '—' : req.notes),
                    ],
                  ),
                ),
                AdminSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Document Information', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _kv('Document type', req.documentType),
                      AdminDocumentPreview(documentUrl: req.documentUrl),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Document URL'),
                              content: SelectableText(req.documentUrl),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Document'),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(req.documentUrl),
                      const SizedBox(height: 8),
                      const Text('Documents are used only for residency verification.'),
                    ],
                  ),
                ),
                AdminSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Document scanning'),
                      SizedBox(height: 8),
                      Text(
                        'OCR extraction will be added later to help admins read document details automatically.',
                      ),
                      SizedBox(height: 8),
                      Text('Extracted name: Not scanned yet'),
                      Text('Extracted address: Not scanned yet'),
                      Text('Confidence: Not available'),
                      // TODO Phase OCR: extract name/address/unit from uploaded document using OCR/ML Kit or cloud OCR.
                    ],
                  ),
                ),
                AdminSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Geofence validation'),
                      SizedBox(height: 8),
                      Text(
                        'Boundary validation will be added later to compare user location against community coordinates.',
                      ),
                      SizedBox(height: 8),
                      Text('Community boundary: Not configured'),
                      Text('Last location check: Not available'),
                      // TODO Phase Geofence: validate resident location against community boundary coordinates.
                    ],
                  ),
                ),
                AdminSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Review Actions', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (req.status == AppConstants.verificationSubmitted) ...[
                        FilledButton(onPressed: vm.isLoading ? null : _approve, child: const Text('Approve')),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: vm.isLoading ? null : _reject,
                          child: const Text('Reject'),
                        ),
                      ] else if (req.status == AppConstants.verificationVerified) ...[
                        const Text('This resident is verified.', style: TextStyle(color: Colors.green)),
                      ] else if (req.status == AppConstants.verificationRejected) ...[
                        const Text('This request is rejected.', style: TextStyle(color: Colors.red)),
                        const SizedBox(height: 6),
                        Text('Reason: ${req.rejectionReason ?? '—'}'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('$k: $v'),
      );

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
