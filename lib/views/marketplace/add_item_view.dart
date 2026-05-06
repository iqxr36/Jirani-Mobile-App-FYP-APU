import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/core/utils/validators.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/viewmodels/item_viewmodel.dart';
import 'package:fyp_flutter_application/views/verification/verification_status_view.dart';
import 'package:fyp_flutter_application/widgets/item_image_picker.dart';
import 'package:fyp_flutter_application/widgets/verification_required_widget.dart';
import 'package:provider/provider.dart';

class AddItemView extends StatefulWidget {
  const AddItemView({super.key});

  @override
  State<AddItemView> createState() => _AddItemViewState();
}

class _AddItemViewState extends State<AddItemView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _feeController = TextEditingController();
  final _depositController = TextEditingController();
  final _pickupController = TextEditingController();

  String _category = AppConstants.itemCategoryTools;
  String _condition = AppConstants.itemConditionGood;
  bool _hasUsageFee = false;
  bool _hasDeposit = false;
  List<String> _imagePaths = const <String>[];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _feeController.dispose();
    _depositController.dispose();
    _pickupController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authVm = context.read<AuthViewModel>();
    final user = authVm.currentUser;
    if (user == null) return;

    if (_imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected. You can still publish this item.')),
      );
    }

    final fee = _hasUsageFee ? double.tryParse(_feeController.text.trim()) : null;
    final deposit = _hasDeposit ? double.tryParse(_depositController.text.trim()) : null;

    final vm = context.read<ItemViewModel>();
    await vm.addItem(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      condition: _condition,
      imagePaths: _imagePaths,
      hasUsageFee: _hasUsageFee,
      feeAmount: fee,
      hasDeposit: _hasDeposit,
      depositAmount: deposit,
      pickupInstructions: _pickupController.text.trim(),
      currentUser: user,
    );

    if (!mounted) return;
    if (vm.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item published successfully.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final vm = context.watch<ItemViewModel>();
    final user = authVm.currentUser;
    final verified = user?.isVerifiedResident ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: user == null || !verified
          ? VerificationRequiredWidget(
              onActionPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const VerificationStatusView()),
                );
              },
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ItemImagePicker(
                        initialImagePaths: _imagePaths,
                        onChanged: (paths) => _imagePaths = paths,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                        validator: Validators.validateItemTitle,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: AppConstants.itemCategoryTools, child: Text('Tools')),
                          DropdownMenuItem(value: AppConstants.itemCategoryKitchen, child: Text('Kitchen')),
                          DropdownMenuItem(value: AppConstants.itemCategoryElectronics, child: Text('Electronics')),
                          DropdownMenuItem(value: AppConstants.itemCategoryCleaning, child: Text('Cleaning')),
                          DropdownMenuItem(value: AppConstants.itemCategoryStudy, child: Text('Study')),
                          DropdownMenuItem(value: AppConstants.itemCategoryEventItems, child: Text('Event Items')),
                          DropdownMenuItem(value: AppConstants.itemCategoryOther, child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _category = v ?? _category),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                        validator: Validators.validateDescription,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _condition,
                        decoration: const InputDecoration(labelText: 'Condition', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: AppConstants.itemConditionNew, child: Text('New')),
                          DropdownMenuItem(value: AppConstants.itemConditionGood, child: Text('Good')),
                          DropdownMenuItem(value: AppConstants.itemConditionUsed, child: Text('Used')),
                        ],
                        onChanged: (v) => setState(() => _condition = v ?? _condition),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Lending Terms',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Charge usage fee'),
                        value: _hasUsageFee,
                        onChanged: (v) => setState(() {
                          _hasUsageFee = v;
                          if (!v) _feeController.clear();
                        }),
                      ),
                      if (_hasUsageFee) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _feeController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Usage fee (RM)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => Validators.validatePositiveAmount(v, fieldName: 'Fee amount'),
                        ),
                      ],
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Require refundable deposit'),
                        value: _hasDeposit,
                        onChanged: (v) => setState(() {
                          _hasDeposit = v;
                          if (!v) _depositController.clear();
                        }),
                      ),
                      if (_hasDeposit) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _depositController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Deposit amount (RM)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => Validators.validatePositiveAmount(v, fieldName: 'Deposit amount'),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Deposit helps protect the item if it is damaged, lost, or returned late.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (!_hasUsageFee && !_hasDeposit)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Chip(label: Text('This item will be listed as free.')),
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pickupController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Pickup instructions',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => Validators.validateRequiredField(v, fieldName: 'Pickup instructions'),
                      ),
                      if (vm.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: vm.isLoading ? null : _submit,
                        child: vm.isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Publish Item'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: vm.isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
