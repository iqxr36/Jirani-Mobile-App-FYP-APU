import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/models/borrow_request.dart';
import 'package:fyp_flutter_application/providers/report_provider.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key, required this.borrowRequest});

  final BorrowRequest borrowRequest;

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  String _type = AppConstants.reportTypeDamagedItem;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  ({String id, String name}) _otherParty(AuthViewModel auth) {
    final uid = auth.currentUser?.uid ?? '';
    final br = widget.borrowRequest;
    if (uid == br.borrowerId) {
      return (id: br.ownerId, name: br.ownerName);
    }
    return (id: br.borrowerId, name: br.borrowerName);
  }

  Future<void> _submit() async {
    final authVm = context.read<AuthViewModel>();
    final auth = authVm.currentUser;
    if (auth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing user profile. Please sign in again.')),
      );
      return;
    }
    final other = _otherParty(authVm);
    final reports = context.read<ReportProvider>();
    try {
      await reports.createReport(
        type: _type,
        relatedBorrowRequestId: widget.borrowRequest.id,
        itemId: widget.borrowRequest.itemId,
        reporterId: auth.uid,
        reporterName: auth.fullName,
        reportedUserId: other.id,
        reportedUserName: other.name,
        title: _titleCtrl.text,
        description: _descCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final busy = context.watch<ReportProvider>().isSubmitting;
    final other = _otherParty(authVm);
    final types = [
      AppConstants.reportTypeDamagedItem,
      AppConstants.reportTypeLostItem,
      AppConstants.reportTypeDepositDispute,
      AppConstants.reportTypeUserMisconduct,
      AppConstants.reportTypeOther,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Create report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Related item: ${widget.borrowRequest.itemTitle}'),
          Text('Reporting: ${other.name}'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
            items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: busy ? null : (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : _submit,
            child: busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit report'),
          ),
        ],
      ),
    );
  }
}
