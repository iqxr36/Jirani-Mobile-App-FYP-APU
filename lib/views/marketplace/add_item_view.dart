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
  String _lendingType = AppConstants.lendingTypeFree;
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

    final fee = _lendingType == AppConstants.lendingTypeSmallFee ? double.tryParse(_feeController.text.trim()) : null;
    final deposit =
        _lendingType == AppConstants.lendingTypeDepositRequired ? double.tryParse(_depositController.text.trim()) : null;

    final vm = context.read<ItemViewModel>();
    await vm.addItem(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      condition: _condition,
      imagePaths: _imagePaths,
      lendingType: _lendingType,
      feeAmount: fee,
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
                        value: _category,
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
                        value: _condition,
                        decoration: const InputDecoration(labelText: 'Condition', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: AppConstants.itemConditionNew, child: Text('New')),
                          DropdownMenuItem(value: AppConstants.itemConditionGood, child: Text('Good')),
                          DropdownMenuItem(value: AppConstants.itemConditionUsed, child: Text('Used')),
                        ],
                        onChanged: (v) => setState(() => _condition = v ?? _condition),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _lendingType,
                        decoration: const InputDecoration(labelText: 'Lending type', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: AppConstants.lendingTypeFree, child: Text('Free')),
                          DropdownMenuItem(value: AppConstants.lendingTypeSmallFee, child: Text('Small fee')),
                          DropdownMenuItem(
                            value: AppConstants.lendingTypeDepositRequired,
                            child: Text('Deposit required'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _lendingType = v ?? _lendingType),
                      ),
                      if (_lendingType == AppConstants.lendingTypeSmallFee) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _feeController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Fee amount (RM)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => Validators.validatePositiveAmount(v, fieldName: 'Fee amount'),
                        ),
                      ],
                      if (_lendingType == AppConstants.lendingTypeDepositRequired) ...[
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
                      ],
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
