import 'package:flutter/material.dart';

class ReportListingView extends StatefulWidget {
  const ReportListingView({super.key, required this.itemId});
  final String itemId;

  @override
  State<ReportListingView> createState() => _ReportListingViewState();
}

class _ReportListingViewState extends State<ReportListingView> {
  final _descriptionController = TextEditingController();
  String _reason = 'Spam';

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Listing')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Spam', child: Text('Spam')),
                DropdownMenuItem(value: 'Inappropriate', child: Text('Inappropriate content')),
                DropdownMenuItem(value: 'Fake', child: Text('Fake listing')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _reason = v ?? _reason),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report flow will be completed in the safety module phase.'),
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }
}
