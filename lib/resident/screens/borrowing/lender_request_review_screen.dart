import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/models/borrow_request.dart';
import 'package:fyp_flutter_application/providers/borrow_request_provider.dart';
import 'package:fyp_flutter_application/providers/review_provider.dart';
import 'package:fyp_flutter_application/resident/screens/reports/create_report_screen.dart';
import 'package:fyp_flutter_application/resident/screens/reviews/leave_review_screen.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/widgets/borrowing/borrow_status_chip.dart';
import 'package:fyp_flutter_application/widgets/borrowing/borrower_mini_card.dart';
import 'package:fyp_flutter_application/widgets/borrowing/fee_deposit_summary_card.dart';
import 'package:fyp_flutter_application/widgets/borrowing/request_date_summary_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class LenderRequestReviewScreen extends StatefulWidget {
  const LenderRequestReviewScreen({super.key, required this.request});
  final BorrowRequest request;

  @override
  State<LenderRequestReviewScreen> createState() => _LenderRequestReviewScreenState();
}

class _LenderRequestReviewScreenState extends State<LenderRequestReviewScreen> {
  String _conditionBefore = AppConstants.borrowConditionBeforeGood;
  String? _handoverProofPath;
  String _conditionAfter = AppConstants.borrowConditionAfterSame;
  final _ownerReturnNotesCtrl = TextEditingController();

  @override
  void dispose() {
    _ownerReturnNotesCtrl.dispose();
    super.dispose();
  }

  BorrowRequest _live(BorrowRequestProvider p) {
    for (final r in p.incomingRequests) {
      if (r.id == widget.request.id) return r;
    }
    return widget.request;
  }

  Future<void> _approve(BorrowRequestProvider provider, String ownerId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve this borrow request?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Approve')),
        ],
      ),
    );
    if (ok != true) return;
    await provider.approveBorrowRequest(requestId: widget.request.id, ownerId: ownerId);
    if (!mounted) return;
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request approved.')));
      Navigator.of(context).pop();
    }
  }

  Future<void> _reject(BorrowRequestProvider provider, String ownerId) async {
    final ctrl = TextEditingController();
    String reason = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _reasonChip('Item unavailable', ctrl),
                _reasonChip('Dates not suitable', ctrl),
                _reasonChip('Borrower profile incomplete', ctrl),
                _reasonChip('Other', ctrl),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
              onChanged: (v) => reason = v.trim(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              reason = ctrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true || reason.isEmpty) return;
    await provider.rejectBorrowRequest(requestId: widget.request.id, ownerId: ownerId, rejectionReason: reason);
    if (!mounted) return;
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected.')));
      Navigator.of(context).pop();
    }
  }

  Widget _reasonChip(String text, TextEditingController ctrl) {
    return ActionChip(
      label: Text(text),
      onPressed: () => setState(() => ctrl.text = text),
    );
  }

  Future<void> _confirmHandover(BorrowRequestProvider provider, String ownerId, BorrowRequest req) async {
    await provider.confirmHandover(
      requestId: req.id,
      ownerId: ownerId,
      conditionBefore: _conditionBefore,
      localProofPath: _handoverProofPath,
    );
    if (!mounted) return;
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Handover confirmed.')));
      setState(() => _handoverProofPath = null);
    }
  }

  Future<void> _confirmReturn(BorrowRequestProvider provider, String ownerId, BorrowRequest req) async {
    await provider.confirmReturn(
      requestId: req.id,
      ownerId: ownerId,
      conditionAfter: _conditionAfter,
      ownerReturnNotes: _ownerReturnNotesCtrl.text,
    );
    if (!mounted) return;
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return confirmed.')));
      Navigator.of(context).pop();
    }
  }

  static String _labelConditionBefore(String v) {
    switch (v) {
      case AppConstants.borrowConditionBeforeExcellent:
        return 'Excellent';
      case AppConstants.borrowConditionBeforeGood:
        return 'Good';
      case AppConstants.borrowConditionBeforeFair:
        return 'Fair';
      case AppConstants.borrowConditionBeforeDamaged:
        return 'Damaged';
      default:
        return v;
    }
  }

  static String _labelConditionAfter(String v) {
    switch (v) {
      case AppConstants.borrowConditionAfterSame:
        return 'Same condition';
      case AppConstants.borrowConditionAfterMinor:
        return 'Minor damage';
      case AppConstants.borrowConditionAfterMajor:
        return 'Major damage';
      case AppConstants.borrowConditionAfterLost:
        return 'Lost';
      default:
        return v;
    }
  }

  Future<void> _pickHandoverImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _handoverProofPath = x.path);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>().currentUser;
    final provider = context.watch<BorrowRequestProvider>();
    final ownerId = auth?.uid ?? '';
    final request = _live(provider);

    return Scaffold(
      appBar: AppBar(title: const Text('Review Borrow Request')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(request.itemTitle),
              subtitle: Text('Request ID: ${request.id}'),
              trailing: BorrowStatusChip(status: request.status),
            ),
          ),
          BorrowerMiniCard(
            name: request.borrowerName,
            email: request.borrowerEmail,
            phone: request.borrowerPhoneNumber,
            isVerified: request.borrowerVerified,
            reputation: request.borrowerReputationScore,
          ),
          RequestDateSummaryCard(
            requestedStartDate: request.requestedStartDate,
            expectedReturnDate: request.expectedReturnDate,
            pickupTime: request.pickupTime,
          ),
          FeeDepositSummaryCard(
            hasUsageFee: request.hasUsageFee,
            usageFeeAmount: request.usageFeeAmount,
            hasDeposit: request.hasDeposit,
            depositAmount: request.depositAmount,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Borrower message: ${request.message.isEmpty ? '—' : request.message}'),
            ),
          ),
          Card(
            color: Colors.orange.shade50,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Review profile trust indicators and request dates before approving.'),
            ),
          ),
          if (request.status == AppConstants.borrowStatusPending) ...[
            FilledButton(
              onPressed: provider.isLoading || ownerId.isEmpty ? null : () => _approve(provider, ownerId),
              child: const Text('Approve Request'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: provider.isLoading || ownerId.isEmpty ? null : () => _reject(provider, ownerId),
              child: const Text('Reject Request'),
            ),
          ],
          if (request.status == AppConstants.borrowStatusApproved)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Waiting for the borrower to confirm pickup readiness.'),
              ),
            ),
          if (request.status == AppConstants.borrowStatusPickupReady) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Confirm Handover'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _conditionBefore,
                      decoration: const InputDecoration(
                        labelText: 'Condition before handover',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        AppConstants.borrowConditionBeforeExcellent,
                        AppConstants.borrowConditionBeforeGood,
                        AppConstants.borrowConditionBeforeFair,
                        AppConstants.borrowConditionBeforeDamaged,
                      ].map((e) => DropdownMenuItem(value: e, child: Text(_labelConditionBefore(e)))).toList(),
                      onChanged: provider.isLoading
                          ? null
                          : (v) => setState(() => _conditionBefore = v ?? _conditionBefore),
                    ),
                    if (_handoverProofPath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('Proof: ${_handoverProofPath!.split(RegExp(r'[/\\]')).last}'),
                      ),
                    OutlinedButton.icon(
                      onPressed: provider.isLoading ? null : _pickHandoverImage,
                      icon: const Icon(Icons.photo_outlined),
                      label: const Text('Optional: attach handover photo'),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              color: Colors.amber.shade50,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Verify unit and item condition before handing over. Borrowing becomes active after you confirm.',
                ),
              ),
            ),
            FilledButton(
              onPressed: provider.isLoading || ownerId.isEmpty ? null : () => _confirmHandover(provider, ownerId, request),
              child: const Text('Confirm Handover'),
            ),
          ],
          if (request.status == AppConstants.borrowStatusActive ||
              request.status == AppConstants.borrowStatusHandedOver)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Active borrowing — waiting for the borrower to submit return.'),
              ),
            ),
          if (request.status == AppConstants.borrowStatusReturnSubmitted) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Borrower return notes: ${request.returnNotes.isEmpty ? '—' : request.returnNotes}'),
                    if (request.returnProofImageUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Image.network(request.returnProofImageUrl, height: 160, fit: BoxFit.contain),
                    ],
                  ],
                ),
              ),
            ),
            DropdownButtonFormField<String>(
              value: _conditionAfter,
              decoration: const InputDecoration(
                labelText: 'Condition after return',
                border: OutlineInputBorder(),
              ),
              items: [
                AppConstants.borrowConditionAfterSame,
                AppConstants.borrowConditionAfterMinor,
                AppConstants.borrowConditionAfterMajor,
                AppConstants.borrowConditionAfterLost,
              ].map((e) => DropdownMenuItem(value: e, child: Text(_labelConditionAfter(e)))).toList(),
              onChanged: provider.isLoading ? null : (v) => setState(() => _conditionAfter = v ?? _conditionAfter),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ownerReturnNotesCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Owner return notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: provider.isLoading || ownerId.isEmpty ? null : () => _confirmReturn(provider, ownerId, request),
              child: const Text('Confirm Item Returned'),
            ),
          ],
          if (request.status == AppConstants.borrowStatusRejected)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Rejected: ${request.rejectionReason.isEmpty ? 'No reason provided' : request.rejectionReason}'),
              ),
            ),
          if (request.status == AppConstants.borrowStatusCompleted) ...[
            Card(
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Completed. Item listing is available again.\nCondition noted: ${request.itemConditionAfter}',
                ),
              ),
            ),
            _OwnerCompletedActions(request: request),
          ],
        ],
      ),
    );
  }
}

class _OwnerCompletedActions extends StatefulWidget {
  const _OwnerCompletedActions({required this.request});

  final BorrowRequest request;

  @override
  State<_OwnerCompletedActions> createState() => _OwnerCompletedActionsState();
}

class _OwnerCompletedActionsState extends State<_OwnerCompletedActions> {
  Future<bool>? _reviewedFuture;
  bool _depsLoaded = false;

  void _reloadReviewState() {
    final uid = context.read<AuthViewModel>().currentUser?.uid;
    if (uid == null) return;
    setState(() {
      _reviewedFuture = context.read<ReviewProvider>().hasUserReviewedBorrowRequest(
            borrowRequestId: widget.request.id,
            reviewerId: uid,
          );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_depsLoaded) return;
    final uid = context.read<AuthViewModel>().currentUser?.uid;
    if (uid == null) return;
    _depsLoaded = true;
    _reviewedFuture = context.read<ReviewProvider>().hasUserReviewedBorrowRequest(
          borrowRequestId: widget.request.id,
          reviewerId: uid,
        );
  }

  Future<void> _withholdDialog(BuildContext context, BorrowRequest req, String ownerId) async {
    final ctrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Withhold deposit'),
          content: TextField(
            controller: ctrl,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Reason (required)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (ctrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      final provider = context.read<BorrowRequestProvider>();
      await provider.setDepositDecision(
        requestId: req.id,
        ownerId: ownerId,
        decision: AppConstants.depositDecisionWithholdDeposit,
        reason: ctrl.text.trim(),
      );
      if (!context.mounted) return;
      final msg = provider.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? 'Deposit decision saved.')),
      );
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _returnDeposit(BuildContext context, BorrowRequest req, String ownerId) async {
    final provider = context.read<BorrowRequestProvider>();
    await provider.setDepositDecision(
      requestId: req.id,
      ownerId: ownerId,
      decision: AppConstants.depositDecisionReturnDeposit,
    );
    if (!context.mounted) return;
    final msg = provider.errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg ?? 'Deposit marked for return.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BorrowRequestProvider>();
    final req = () {
      for (final r in provider.incomingRequests) {
        if (r.id == widget.request.id) return r;
      }
      return widget.request;
    }();
    final ownerId = context.watch<AuthViewModel>().currentUser?.uid ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FutureBuilder<bool>(
          future: _reviewedFuture,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
              );
            }
            final reviewed = snap.data!;
            if (reviewed) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Review submitted'),
              );
            }
            return FilledButton(
              onPressed: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => LeaveReviewScreen(
                      borrowRequest: req,
                      role: AppConstants.reviewRoleOwnerToBorrower,
                    ),
                  ),
                );
                if (ok == true) _reloadReviewState();
              },
              child: const Text('Leave Review'),
            );
          },
        ),
        if (req.hasDeposit) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Deposit decision', style: Theme.of(context).textTheme.titleSmall),
                  Text('Status: ${req.depositDecision}'),
                  if (req.depositDecisionReason.isNotEmpty) Text('Reason: ${req.depositDecisionReason}'),
                  if (req.depositDecision == AppConstants.depositDecisionPending) ...[
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: provider.isLoading || ownerId.isEmpty ? null : () => _returnDeposit(context, req, ownerId),
                      child: const Text('Return Deposit'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: provider.isLoading || ownerId.isEmpty ? null : () => _withholdDialog(context, req, ownerId),
                      child: const Text('Withhold Deposit'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CreateReportScreen(borrowRequest: req),
              ),
            );
          },
          child: const Text('Report issue'),
        ),
      ],
    );
  }
}
