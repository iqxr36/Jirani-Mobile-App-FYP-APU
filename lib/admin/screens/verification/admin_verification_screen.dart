import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/theme/admin_button_styles.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/services/admin_verification_review_service.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_ocr_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/admin/logic/widgets/ocr_review_dialog.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/admin/providers/admin_provider.dart';
import 'package:jirani/shared/models/extracted_document_data.dart';
import 'package:jirani/shared/models/verification_request.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

final _reviewService = AdminVerificationReviewService();

// Admin verification UI feature: shows verification inbox and selected request review details.
class AdminVerificationScreen extends StatelessWidget {
  const AdminVerificationScreen({
    super.key,
    required this.selectedRequestId,
    required this.onSelectRequest,
  });

  final String? selectedRequestId;
  final ValueChanged<String> onSelectRequest;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final requests = admin.verificationRequests;
    final selected = _selectedRequest(requests);

    if (admin.isLoading && requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return AdminPageScroll(
      children: [
        const AdminCommunityScopeBanner(),
        const SizedBox(height: 20),
        AdminControlBar(
          title: 'Pending Verification Requests',
          subtitle:
              'Approve only when document, resident identity, and community details match.',
          controls: [
            DropdownButton<String>(
              value: admin.selectedStatusFilter,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                DropdownMenuItem(value: 'verified', child: Text('Verified')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                DropdownMenuItem(value: 'all', child: Text('All')),
              ],
              onChanged: (value) {
                if (value != null) {
                  context.read<AdminProvider>().setStatusFilter(value);
                }
              },
            ),
          ],
        ),
        if (admin.errorMessage != null) ...[
          const SizedBox(height: 12),
          AdminInlineAlert(message: admin.errorMessage!),
        ],
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = JiraniResponsive.isAdminWide(constraints.maxWidth);
            final paneHeight = (MediaQuery.sizeOf(context).height - 220).clamp(
              480.0,
              760.0,
            );
            final list = AdminVerificationRequestList(
              requests: requests,
              selectedId: selected?.id,
              onSelect: onSelectRequest,
            );
            final detail = AdminVerificationDetail(request: selected);

            if (wide) {
              return SizedBox(
                height: paneHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 340, child: list),
                    const SizedBox(width: 20),
                    Expanded(child: detail),
                  ],
                ),
              );
            }

            return Column(
              children: [
                SizedBox(height: 360, child: list),
                const SizedBox(height: 20),
                detail,
              ],
            );
          },
        ),
      ],
    );
  }

  VerificationRequest? _selectedRequest(List<VerificationRequest> requests) {
    if (requests.isEmpty) return null;
    if (selectedRequestId == null) return requests.first;
    return requests.cast<VerificationRequest?>().firstWhere(
      (request) => request?.id == selectedRequestId,
      orElse: () => requests.first,
    );
  }
}

// Admin verification UI feature: lists verification requests filtered by selected status.
class AdminVerificationRequestList extends StatelessWidget {
  const AdminVerificationRequestList({
    super.key,
    required this.requests,
    required this.selectedId,
    required this.onSelect,
  });

  final List<VerificationRequest> requests;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: 'Requests',
      action: requests.length.toString(),
      padding: EdgeInsets.zero,
      fillChild: true,
      child: requests.isEmpty
          ? const AdminEmptyPanelMessage(
              icon: Icons.mark_email_read_rounded,
              title: 'No requests in this queue',
              body: 'New resident verification submissions will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final request = requests[index];
                final selected = request.id == selectedId;
                return Material(
                  color: selected
                      ? AdminColors.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onSelect(request.id),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          AdminAvatar(name: request.fullName),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.fullName.isEmpty
                                      ? 'Resident request'
                                      : request.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AdminColors.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatRequestDate(request.submittedAt),
                                  style: const TextStyle(
                                    color: AdminColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatRequestDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// Admin verification UI feature: shows OCR fields, document proof, and approve/reject actions.
class AdminVerificationDetail extends StatelessWidget {
  const AdminVerificationDetail({super.key, required this.request});

  final VerificationRequest? request;

  @override
  Widget build(BuildContext context) {
    if (request == null) {
      return const AdminPanel(
        title: 'Detail View',
        child: AdminEmptyPanelMessage(
          icon: Icons.description_rounded,
          title: 'Select a request',
          body:
              'Resident identity, community details, and uploaded documents show here.',
        ),
      );
    }

    final r = request!;
    final canReview = _canAdminReview(r);
    return AdminPanel(
      title: r.fullName.isEmpty ? 'Resident Details' : r.fullName,
      action: r.status,
      fillChild: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                AdminInfoTile(label: 'Email Address', value: r.email),
                AdminInfoTile(label: 'Phone Number', value: r.phoneNumber),
                AdminInfoTile(label: 'Community Name', value: r.communityName),
                AdminInfoTile(label: 'Unit Number', value: r.unitNumber),
              ],
            ),
            const SizedBox(height: 20),
            AdminExtractedTextPanel(request: r),
            if (r.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              AdminStatusNotice(
                icon: Icons.sticky_note_2_rounded,
                title: 'Resident Notes',
                body: r.notes,
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: canReview ? () => _approve(context, r) : null,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Approve Verification'),
                ),
                FilledButton.icon(
                  style: AdminButtonStyles.dangerFilled(context),
                  onPressed: canReview ? () => _reject(context, r) : null,
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('Reject Request'),
                ),
                if (r.documentUrl.trim().isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _openDocument(context, r.documentUrl),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open Document'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canAdminReview(VerificationRequest request) {
    if (request.status == AppConstants.verificationRejected ||
        request.status == AppConstants.verificationVerified) {
      return false;
    }
    if (request.status == AppConstants.verificationSubmitted ||
        request.status == AppConstants.verificationRequestPending) {
      return true;
    }
    if (request.adminStatus == AppConstants.adminStatusOcrMatched ||
        request.adminStatus == AppConstants.adminStatusManualCheckRequired ||
        request.adminStatus == AppConstants.adminStatusPendingReview ||
        request.adminStatus == AppConstants.adminStatusProcessing) {
      return true;
    }
    return false;
  }

  // Admin verification UI feature: approves the selected request using reviewed OCR data if provided.
  Future<void> _approve(
    BuildContext context,
    VerificationRequest request,
  ) async {
    final reviewedOcrData = await _reviewOcrData(context, request);
    if (reviewedOcrData == null || !context.mounted) return;

    final adminUid = context.read<AuthViewModel>().currentAdmin?.uid ?? '';
    await context.read<AdminProvider>().approveRequest(
      request: request,
      adminUid: adminUid,
      reviewedOcrData: reviewedOcrData,
    );
    if (!context.mounted) return;
    final error = context.read<AdminProvider>().errorMessage;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Verification approved.')));
  }

  // Admin verification OCR UI feature: opens the extracted-field review dialog before approval.
  Future<ExtractedDocumentData?> _reviewOcrData(
    BuildContext context,
    VerificationRequest request,
  ) {
    final parsedData = _reviewService.initialReviewData(request);
    return showDialog<ExtractedDocumentData>(
      context: context,
      builder: (context) => OcrReviewDialog(initialData: parsedData),
    );
  }

  // Admin verification UI feature: rejects the selected request after collecting a reason.
  Future<void> _reject(
    BuildContext context,
    VerificationRequest request,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const AdminRejectDialog(),
    );
    if (reason == null || reason.trim().isEmpty || !context.mounted) return;
    final adminUid = context.read<AuthViewModel>().currentAdmin?.uid ?? '';
    await context.read<AdminProvider>().rejectRequest(
      request: request,
      adminUid: adminUid,
      rejectionReason: reason,
    );
    if (!context.mounted) return;
    final error = context.read<AdminProvider>().errorMessage;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Verification rejected.')));
  }

  // Admin verification UI feature: opens the uploaded proof document for visual inspection.
  Future<void> _openDocument(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open document link.')),
    );
  }
}

class AdminRejectDialog extends StatefulWidget {
  const AdminRejectDialog({super.key});

  @override
  State<AdminRejectDialog> createState() => _AdminRejectDialogState();
}

class _AdminRejectDialogState extends State<AdminRejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject verification'),
      content: TextField(
        controller: _controller,
        minLines: 3,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: 'Reason',
          hintText: 'Explain what the resident needs to fix.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: AdminButtonStyles.dangerFilled(context),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Reject Request'),
        ),
      ],
    );
  }
}
