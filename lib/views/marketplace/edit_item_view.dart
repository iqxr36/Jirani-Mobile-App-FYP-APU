import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/core/utils/validators.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/viewmodels/item_viewmodel.dart';
import 'package:fyp_flutter_application/widgets/item_image_picker.dart';
import 'package:provider/provider.dart';

class EditItemView extends StatefulWidget {
  const EditItemView({super.key, required this.itemId});
  final String itemId;

  @override
  State<EditItemView> createState() => _EditItemViewState();
}

class _EditItemViewState extends State<EditItemView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _feeController = TextEditingController();
  final _depositController = TextEditingController();
  final _pickupController = TextEditingController();
  String _category = AppConstants.itemCategoryTools;
  String _condition = AppConstants.itemConditionGood;
  String _lendingType = AppConstants.lendingTypeFree;
  List<String> _newImagePaths = const <String>[];
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemViewModel>().loadItemById(widget.itemId);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _feeController.dispose();
    _depositController.dispose();
    _pickupController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<ItemViewModel>();
    await vm.updateItem(
      itemId: widget.itemId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      condition: _condition,
      lendingType: _lendingType,
      feeAmount: _lendingType == AppConstants.lendingTypeSmallFee ? double.tryParse(_feeController.text.trim()) : null,
      depositAmount: _lendingType == AppConstants.lendingTypeDepositRequired
          ? double.tryParse(_depositController.text.trim())
          : null,
      pickupInstructions: _pickupController.text.trim(),
      newImagePaths: _newImagePaths.isEmpty ? null : _newImagePaths,
    );
    if (!mounted) return;
    if (vm.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item updated successfully.')));
      Navigator.of(context).pop();
    }
  }

  Future<void> _archive() async {
    final vm = context.read<ItemViewModel>();
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive item?'),
        content: const Text('This item will be hidden from available marketplace listings.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Archive')),
        ],
      ),
    );
    if (shouldArchive != true) return;

    await vm.archiveItem(widget.itemId);
    if (!mounted) return;
    if (vm.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item archived.')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final vm = context.watch<ItemViewModel>();
    final item = vm.selectedItem;

    if (vm.isLoading && item == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Item')),
        body: Center(child: Text(vm.errorMessage ?? 'Item not found.')),
      );
    }

    final isOwner = authVm.currentUser?.uid == item.ownerId;
    if (!_seeded) {
      _titleController.text = item.title;
      _descriptionController.text = item.description;
      _pickupController.text = item.pickupInstructions;
      _category = item.category;
      _condition = item.condition;
      _lendingType = item.lendingType;
      if (item.feeAmount != null) _feeController.text = item.feeAmount!.toStringAsFixed(2);
      if (item.depositAmount != null) _depositController.text = item.depositAmount!.toStringAsFixed(2);
      _seeded = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
      body: !isOwner
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('You are not authorized to edit this item.'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (item.imageUrls.isNotEmpty) ...[
                        SizedBox(
                          height: 90,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: item.imageUrls.length,
                            separatorBuilder: (_, index) => const SizedBox(width: 8),
                            itemBuilder: (context, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrls[i],
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      ItemImagePicker(
                        initialImagePaths: const [],
                        onChanged: (paths) => _newImagePaths = paths,
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
                      DropdownButtonFormField<String>(
                        initialValue: _lendingType,
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
                          decoration: const InputDecoration(labelText: 'Fee amount (RM)', border: OutlineInputBorder()),
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
                        onPressed: vm.isLoading ? null : _save,
                        child: const Text('Save Changes'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: vm.isLoading ? null : _archive,
                        child: const Text('Archive Item'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
