import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/providers/admin_provider.dart';
import 'package:fyp_flutter_application/providers/auth_provider.dart';
import 'package:fyp_flutter_application/screens/admin/admin_unauthorized_screen.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_document_preview.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_section_card.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_status_chip.dart';
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
    final vm = context.read<AdminProvider>();
    final req = vm.selectedRequest;
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('Admin approve/reject adminUid: $adminUid');
    debugPrint('Request ID: ${req?.id}');
    debugPrint('Resident UID: ${req?.userId}');
    debugPrint(
      '[AdminDetails][approve] requestId=${req?.id} residentUid=${req?.userId} status=${req?.status} adminUid=$adminUid',
    );
    if (req == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification request ID is missing.')),
      );
      return;
    }
    if (req.id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification request ID is missing.')),
      );
      return;
    }
    if (req.userId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resident user ID is missing from this verification request.')),
      );
      return;
    }
    if (adminUid == null || adminUid.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin user ID is missing. Please log in again.')),
      );
      return;
    }

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resident verified successfully.')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
    }
  }

  Future<void> _reject() async {
    final vm = context.read<AdminProvider>();
    final req = vm.selectedRequest;
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('Admin approve/reject adminUid: $adminUid');
    debugPrint('Request ID: ${req?.id}');
    debugPrint('Resident UID: ${req?.userId}');
    debugPrint(
      '[AdminDetails][reject] requestId=${req?.id} residentUid=${req?.userId} status=${req?.status} adminUid=$adminUid',
    );
    if (req == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification request ID is missing.')),
      );
      return;
    }
    if (req.id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification request ID is missing.')),
      );
      return;
    }
    if (req.userId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resident user ID is missing from this verification request.')),
      );
      return;
    }
    if (adminUid == null || adminUid.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin user ID is missing. Please log in again.')),
      );
      return;
    }

    String reason = '';
    String? reasonError;
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
                onChanged: (v) {
                  reason = v;
                  if (reasonError != null && v.trim().isNotEmpty) {
                    setStateDialog(() => reasonError = null);
                  }
                },
              ),
              if (reasonError != null) ...[
                const SizedBox(height: 8),
                Text(reasonError!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                reason = controller.text.trim();
                if (reason.isEmpty) {
                  setStateDialog(() => reasonError = 'Rejection reason is required.');
                  return;
                }
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification request rejected.')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
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
    final normalizedStatus = req?.status.trim().toLowerCase() ?? '';
    final submittedStatus = AppConstants.verificationSubmitted.toLowerCase();
    final verifiedStatus = AppConstants.verificationVerified.toLowerCase();
    final rejectedStatus = AppConstants.verificationRejected.toLowerCase();
    final pendingStatus = AppConstants.verificationPending.toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(title: const Text('Verification Request Details')),
      body: req == null
          ? Center(
              child: vm.isLoading ? const CircularProgressIndicator() : Text(vm.errorMessage ?? 'Request not found.'),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1200;
                final left = Column(
                  children: [
                    AdminSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFACEFE7),
                                child: Text(req.fullName.isNotEmpty ? req.fullName[0].toUpperCase() : 'R'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(req.fullName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    const Text('Tenant Applicant', style: TextStyle(color: Color(0xFF3E494A))),
                                  ],
                                ),
                              ),
                              AdminStatusChip(status: req.status),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _kv('Resident ID', req.userId),
                          _kv('Unit number', req.unitNumber),
                          _kv('Phone number', req.phoneNumber),
                          _kv('Email address', req.email),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const AdminSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Security checklist', style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          Text('• Email verified / not verified'),
                          Text('• Phone verified / not verified'),
                          Text('• Address proof submitted/verified'),
                          Text('• Background check (future placeholder)'),
                        ],
                      ),
                    ),
                  ],
                );

                final middle = Column(
                  children: [
                    AdminSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${req.documentType} uploaded', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          AdminDocumentPreview(documentUrl: req.documentUrl),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const AdminSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('OCR Extracted Information', style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          Text('Extracted Name: Not scanned yet'),
                          Text('Extracted Address: Not scanned yet'),
                          Text('Confidence: Not available'),
                          SizedBox(height: 8),
                          Text('OCR will be implemented later.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const AdminSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Geofence Validation', style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          Text('Boundary: Not configured'),
                          Text('Last location check: Not available'),
                          SizedBox(height: 8),
                          Text('Geofence boundary logic will be implemented later.'),
                        ],
                      ),
                    ),
                  ],
                );

                final right = Column(
                  children: [
                    AdminSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Review Actions', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          if (normalizedStatus == submittedStatus) ...[
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                backgroundColor: const Color(0xFF00535B),
                              ),
                              onPressed: vm.isLoading ? null : _approve,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Approve Resident'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                              onPressed: vm.isLoading ? null : _reject,
                              icon: const Icon(Icons.cancel_outlined, color: Color(0xFFBA1A1A)),
                              label: const Text('Reject Request', style: TextStyle(color: Color(0xFFBA1A1A))),
                            ),
                          ] else if (normalizedStatus == verifiedStatus) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFD6F4F1), borderRadius: BorderRadius.circular(10)),
                              child: const Text('Resident verified.', style: TextStyle(color: Color(0xFF006D77))),
                            ),
                          ] else if (normalizedStatus == rejectedStatus) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFFFDAD6), borderRadius: BorderRadius.circular(10)),
                              child: Text('Request rejected.\nReason: ${req.rejectionReason ?? '—'}', style: const TextStyle(color: Color(0xFFBA1A1A))),
                            ),
                          ] else if (normalizedStatus == pendingStatus) ...[
                            const Text('This request is pending review.'),
                          ] else ...[
                            Text('No admin action available for status: ${req.status}'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const AdminSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recent History', style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          Text('• Profile created'),
                          Text('• Document uploaded'),
                          Text('• Review pending'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFFE4B8), borderRadius: BorderRadius.circular(12)),
                      child: const Text(
                        'Verify unit number and uploaded document before approval. Reject unclear or mismatched documents with a clear reason.',
                      ),
                    ),
                  ],
                );

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
                        Expanded(
                          child: Text(
                            'Review Verification: ${req.fullName}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Icon(Icons.help_outline),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: const Color(0xFFACEFE7),
                          child: Text(user.email.isNotEmpty ? user.email[0].toUpperCase() : 'A'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: left),
                          const SizedBox(width: 12),
                          Expanded(flex: 4, child: middle),
                          const SizedBox(width: 12),
                          Expanded(flex: 3, child: right),
                        ],
                      )
                    else ...[
                      left,
                      const SizedBox(height: 12),
                      middle,
                      const SizedBox(height: 12),
                      right,
                    ],
                  ],
                );
              },
            ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('$k: $v'),
      );
}
