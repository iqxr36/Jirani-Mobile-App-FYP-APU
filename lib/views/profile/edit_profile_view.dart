import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/utils/validators.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/widgets/custom_button.dart';
import 'package:fyp_flutter_application/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _communityController;
  late final TextEditingController _unitController;
  late final TextEditingController _photoUrlController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _communityController = TextEditingController(text: user?.communityName ?? '');
    _unitController = TextEditingController(text: user?.unitNumber ?? '');
    _photoUrlController = TextEditingController(text: user?.profileImageUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _communityController.dispose();
    _unitController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<AuthViewModel>();
    vm.clearError();

    await vm.saveProfile(
      fullName: _nameController.text,
      phoneNumber: Validators.normalizePhoneNumber(_phoneController.text),
      communityName: _communityController.text,
      unitNumber: _unitController.text,
      profileImageUrl: _photoUrlController.text.trim(),
    );

    if (!mounted) return;
    if (context.read<AuthViewModel>().errorMessage == null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Full name',
                  validator: Validators.validateFullName,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Phone number',
                  keyboardType: TextInputType.phone,
                  helperText: 'Include country code, e.g. +60 for Malaysia.',
                  validator: Validators.validatePhoneNumberWithCountryCode,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _communityController,
                  labelText: 'Building / community',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _unitController,
                  labelText: 'Unit number',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _photoUrlController,
                  labelText: 'Profile image URL (optional)',
                  keyboardType: TextInputType.url,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final uri = Uri.tryParse(v.trim());
                    if (uri == null || !uri.hasScheme) return 'Enter a valid URL.';
                    return null;
                  },
                ),
                if (vm.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Save changes',
                  isLoading: vm.isLoading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
