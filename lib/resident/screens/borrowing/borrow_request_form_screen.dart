import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/data/models/item_model.dart';
import 'package:fyp_flutter_application/providers/borrow_request_provider.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/widgets/borrowing/fee_deposit_summary_card.dart';
import 'package:provider/provider.dart';

import 'borrow_request_sent_screen.dart';

class BorrowRequestFormScreen extends StatefulWidget {
  const BorrowRequestFormScreen({super.key, required this.item});
  final ItemModel item;

  @override
  State<BorrowRequestFormScreen> createState() => _BorrowRequestFormScreenState();
}

class _BorrowRequestFormScreenState extends State<BorrowRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _returnDate;
  bool _agreed = false;

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final initial = _startDate ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _startDate = selected);
  }

  Future<void> _pickReturnDate() async {
    final initial = _returnDate ?? (_startDate ?? DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _returnDate = selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start date and return date are required.')));
      return;
    }
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please acknowledge the borrowing policy.')));
      return;
    }

    final authVm = context.read<AuthViewModel>();
    final borrower = authVm.currentUser;
    if (borrower == null) return;
    if (borrower.uid == widget.item.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot request your own item.')));
      return;
    }
    final provider = context.read<BorrowRequestProvider>();
    await provider.createBorrowRequest(
      item: widget.item,
      borrower: borrower,
      requestedStartDate: _startDate!,
      expectedReturnDate: _returnDate!,
      pickupTime: _pickupCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
    );
    if (!mounted) return;
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BorrowRequestSentScreen(item: widget.item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BorrowRequestProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Request to Borrow')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: widget.item.imageUrls.isNotEmpty
                            ? Image.network(widget.item.imageUrls.first, fit: BoxFit.cover)
                            : Container(color: Colors.grey.shade200, child: const Icon(Icons.image_outlined)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.item.title, style: Theme.of(context).textTheme.titleMedium),
                          Text('Owner: ${widget.item.ownerName}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FeeDepositSummaryCard(
              hasUsageFee: widget.item.hasUsageFee,
              usageFeeAmount: widget.item.feeAmount,
              hasDeposit: widget.item.hasDeposit,
              depositAmount: widget.item.depositAmount,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_startDate == null ? 'Requested start date' : 'Start: ${_fmtDate(_startDate!)}'),
              trailing: const Icon(Icons.date_range_outlined),
              onTap: _pickStartDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_returnDate == null ? 'Expected return date' : 'Return: ${_fmtDate(_returnDate!)}'),
              trailing: const Icon(Icons.event_outlined),
              onTap: _pickReturnDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pickupCtrl,
              decoration: const InputDecoration(labelText: 'Pickup time', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Pickup time is required.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message to owner (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I agree to return the item on time and in the same condition. Deposit may be withheld if the item is damaged, lost, or returned late.',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: provider.isLoading ? null : _submit,
              child: provider.isLoading ? const CircularProgressIndicator() : const Text('Send Borrow Request'),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
