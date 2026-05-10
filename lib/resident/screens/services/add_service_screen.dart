import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/data/models/app_user.dart';
import 'package:fyp_flutter_application/providers/service_provider.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _availCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _category = AppConstants.serviceCategoryOther;
  String _priceType = AppConstants.servicePriceTypeFree;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _availCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(AppUser user) async {
    final svc = context.read<ServiceProvider>();
    double? amount;
    final pt = _priceCtrl.text.trim();
    if (pt.isNotEmpty) amount = double.tryParse(pt);

    try {
      await svc.createService(
        provider: user,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        category: _category,
        priceType: _priceType,
        priceAmount: amount,
        availability: _availCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service added.')));
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
    final user = context.watch<AuthViewModel>().currentUser;
    final busy = context.watch<ServiceProvider>().isLoading;
    final categories = [
      AppConstants.serviceCategoryCleaning,
      AppConstants.serviceCategoryTutoring,
      AppConstants.serviceCategoryRepair,
      AppConstants.serviceCategoryDelivery,
      AppConstants.serviceCategoryPetCare,
      AppConstants.serviceCategoryOther,
    ];
    final priceTypes = [
      AppConstants.servicePriceTypeFree,
      AppConstants.servicePriceTypeFixed,
      AppConstants.servicePriceTypeNegotiable,
    ];

    if (user == null || !user.isVerifiedResident) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add service')),
        body: const Center(child: Text('Only verified residents can add services.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add service')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: busy ? null : (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _priceType,
            decoration: const InputDecoration(labelText: 'Price type', border: OutlineInputBorder()),
            items: priceTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: busy ? null : (v) => setState(() => _priceType = v ?? _priceType),
          ),
          if (_priceType != AppConstants.servicePriceTypeFree) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price amount (optional for negotiable)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _availCtrl,
            decoration: const InputDecoration(
              labelText: 'Availability',
              border: OutlineInputBorder(),
              hintText: 'e.g. Weekends after 2pm',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : () => _save(user),
            child: busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
