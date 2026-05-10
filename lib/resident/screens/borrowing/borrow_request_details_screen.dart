import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/models/borrow_request.dart';
import 'package:fyp_flutter_application/providers/borrow_request_provider.dart';
import 'package:fyp_flutter_application/providers/review_provider.dart';
import 'package:fyp_flutter_application/resident/screens/reports/create_report_screen.dart';
import 'package:fyp_flutter_application/resident/screens/reviews/leave_review_screen.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/widgets/borrowing/borrow_status_chip.dart';
import 'package:fyp_flutter_application/widgets/borrowing/fee_deposit_summary_card.dart';
import 'package:fyp_flutter_application/widgets/borrowing/request_date_summary_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class BorrowRequestDetailsScreen extends StatefulWidget {
  const BorrowRequestDetailsScreen({super.key, required this.request});
  final BorrowRequest request;

  @override
  State<BorrowRequestDetailsScreen> createState() => _BorrowRequestDetailsScreenState();
}

class _BorrowRequestDetailsScreenState extends State<BorrowRequestDetailsScreen> {
  final _returnNotesCtrl = TextEditingController();
  String? _pickupProofPath;
  String? _returnProofPath;

  @override
  void dispose() {
    _returnNotesCtrl.dispose();
    super.dispose();
  }

  BorrowRequest _live(BorrowRequestProvider p) {
    for (final r in p.myBorrowRequests) {
      if (r.id == widget.request.id) return r;
    }
    return widget.request;
  }

  Future<void> _pickImage(void Function(String path) onPicked) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x != null) onPicked(x.path);
  }

  Future<void> _cancel(BuildContext context, BorrowRequest req) async {
    final authVm = context.read<AuthViewModel>();
    final user = authVm.currentUser;
    if (user == null) return;
    final provider = context.read<BorrowRequestProvider>();
    await provider.cancelBorrowRequest(requestId: req.id, borrowerId: user.uid);
    if (!context.mounted) return;
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request cancelled.')));
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmPickup(BuildContext context, BorrowRequest req) async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;
    final provider = context.read<BorrowRequestProvider>();
    await provider.confirmPickupReady(
      requestId: req.id,
      borrowerId: user.uid,
      localProofPath: _pickupProofPath,
    );
    if (!context.mounted) return;
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pickup readiness confirmed.')));
      setState(() => _pickupProofPath = null);
    }
  }

  Future<void> _submitReturn(BuildContext context, BorrowRequest req) async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;
    final provider = context.read<BorrowRequestProvider>();
    await provider.submitReturn(
      requestId: req.id,
      borrowerId: user.uid,
      returnNotes: _returnNotesCtrl.text,
      localProofPath: _returnProofPath,
    );
    if (!context.mounted) return;
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return submitted.')));
      setState(() => _returnProofPath = null);
    }
  }

  bool _isActiveBorrowing(String status) {
    final s = status.trim().toLowerCase();
    return s == AppConstants.borrowStatusHandedOver || s == AppConstants.borrowStatusActive;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BorrowRequestProvider>();
    final req = _live(provider);

    return Scaffold(
      appBar: AppBar(title: const Text('Borrow Request Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: req.itemImageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(req.itemImageUrl, width: 52, height: 52, fit: BoxFit.cover),
                    )
                  : const CircleAvatar(child: Icon(Icons.image_outlined)),
              title: Text(req.itemTitle),
              subtitle: Text('Owner: ${req.ownerName} (${req.ownerEmail})'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Status: '),
              BorrowStatusChip(status: req.status),
            ],
          ),
          const SizedBox(height: 8),
          RequestDateSummaryCard(
            requestedStartDate: req.requestedStartDate,
            expectedReturnDate: req.expectedReturnDate,
            pickupTime: req.pickupTime,
          ),
          FeeDepositSummaryCard(
            hasUsageFee: req.hasUsageFee,
            usageFeeAmount: req.usageFeeAmount,
            hasDeposit: req.hasDeposit,
            depositAmount: req.depositAmount,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Message: ${req.message.isEmpty ? '—' : req.message}'),
            ),
          ),
          if (req.status == AppConstants.borrowStatusRejected && req.rejectionReason.isNotEmpty)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Rejection reason: ${req.rejectionReason}'),
              ),
            ),
          if (req.status == AppConstants.borrowStatusPickupReady)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Waiting for the owner to confirm handover.'),
              ),
            ),
          if (req.status == AppConstants.borrowStatusApproved) ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Pickup and handover confirmation will notify the owner.'),
              ),
            ),
            if (_pickupProofPath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Proof selected: ${_pickupProofPath!.split(RegExp(r'[/\\]')).last}'),
              ),
            OutlinedButton.icon(
              onPressed: () => _pickImage((path) => setState(() => _pickupProofPath = path)),
              icon: const Icon(Icons.photo_outlined),
              label: const Text('Optional: attach pickup photo'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: provider.isLoading ? null : () => _confirmPickup(context, req),
              child: const Text('Confirm Pickup Ready'),
            ),
          ],
          if (_isActiveBorrowing(req.status)) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active borrowing', style: Theme.of(context).textTheme.titleMedium),
                    if (req.handoverConfirmedAt != null)
                      Text('Handover: ${_fmtDt(req.handoverConfirmedAt!)}'),
                    if (req.itemConditionBefore.isNotEmpty)
                      Text('Condition at handover: ${req.itemConditionBefore}'),
                  ],
                ),
              ),
            ),
            TextField(
              controller: _returnNotesCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Return notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            if (_returnProofPath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Proof selected: ${_returnProofPath!.split(RegExp(r'[/\\]')).last}'),
              ),
            OutlinedButton.icon(
              onPressed: () => _pickImage((path) => setState(() => _returnProofPath = path)),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Optional: attach return photo'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: provider.isLoading ? null : () => _submitReturn(context, req),
              child: const Text('Submit Return'),
            ),
          ],
          if (req.status == AppConstants.borrowStatusReturnSubmitted)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Waiting for the owner to confirm the returned item.'),
              ),
            ),
          if (req.status == AppConstants.borrowStatusCompleted) ...[
            Card(
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Completed', style: Theme.of(context).textTheme.titleMedium),
                    if (req.completedAt != null) Text('Completed at: ${_fmtDt(req.completedAt!)}'),
                    if (req.itemConditionAfter.isNotEmpty) Text('Condition noted by owner: ${req.itemConditionAfter}'),
                    if (req.ownerReturnNotes.isNotEmpty) Text('Owner notes: ${req.ownerReturnNotes}'),
                  ],
                ),
              ),
            ),
            _BorrowerCompletedActions(request: req),
          ],
          if (req.returnNotes.isNotEmpty && req.status != AppConstants.borrowStatusActive)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Your return notes: ${req.returnNotes}'),
              ),
            ),
          if (req.returnProofImageUrl.isNotEmpty && req.status != AppConstants.borrowStatusActive)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.network(req.returnProofImageUrl, height: 160, fit: BoxFit.contain),
              ),
            ),
          if (req.status == AppConstants.borrowStatusPending)
            OutlinedButton(
              onPressed: provider.isLoading ? null : () => _cancel(context, req),
              child: const Text('Cancel Request'),
            ),
        ],
      ),
    );
  }

  static String _fmtDt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _BorrowerCompletedActions extends StatefulWidget {
  const _BorrowerCompletedActions({required this.request});

  final BorrowRequest request;

  @override
  State<_BorrowerCompletedActions> createState() => _BorrowerCompletedActionsState();
}

class _BorrowerCompletedActionsState extends State<_BorrowerCompletedActions> {
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

  @override
  Widget build(BuildContext context) {
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
                      borrowRequest: widget.request,
                      role: AppConstants.reviewRoleBorrowerToOwner,
                    ),
                  ),
                );
                if (ok == true) _reloadReviewState();
              },
              child: const Text('Leave Review'),
            );
          },
        ),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CreateReportScreen(borrowRequest: widget.request),
              ),
            );
          },
          child: const Text('Report issue'),
        ),
      ],
    );
  }
}
