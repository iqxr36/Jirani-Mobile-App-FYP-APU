import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/models/service_model.dart';
import 'package:fyp_flutter_application/providers/service_provider.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class ServiceRequestFormScreen extends StatefulWidget {
  const ServiceRequestFormScreen({super.key, required this.service});

  final ServiceModel service;

  @override
  State<ServiceRequestFormScreen> createState() => _ServiceRequestFormScreenState();
}

class _ServiceRequestFormScreenState extends State<ServiceRequestFormScreen> {
  final _messageCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _messageCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing user profile. Please sign in again.')),
      );
      return;
    }
    final pro = context.read<ServiceProvider>();
    try {
      await pro.createServiceRequest(
        service: widget.service,
        requester: user,
        message: _messageCtrl.text,
        preferredDate: _date,
        preferredTime: _timeCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<ServiceProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: Text('Request: ${widget.service.title}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _messageCtrl,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: Text(
              'Preferred date: ${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: busy ? null : _pickDate,
          ),
          TextField(
            controller: _timeCtrl,
            decoration: const InputDecoration(
              labelText: 'Preferred time',
              border: OutlineInputBorder(),
              hintText: 'e.g. 14:00–16:00',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : _submit,
            child: busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit request'),
          ),
        ],
      ),
    );
  }
}
