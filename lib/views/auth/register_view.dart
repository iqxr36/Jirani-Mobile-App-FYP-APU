import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/utils/validators.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/widgets/custom_button.dart';
import 'package:fyp_flutter_application/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _termsAccepted = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms and Community Guidelines.')),
      );
      return;
    }

    await context.read<AuthViewModel>().register(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: Validators.normalizePhoneNumber(_phoneController.text),
          password: _passwordController.text,
          termsAccepted: true,
        );

    if (!mounted) return;
    final vm = context.read<AuthViewModel>();
    if (vm.errorMessage == null && vm.currentUser != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. A verification email has been sent to your email address.'),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _fullNameController,
                  labelText: 'Full name',
                  validator: Validators.validateFullName,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
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
                  controller: _passwordController,
                  labelText: 'Password',
                  obscureText: true,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm password',
                  obscureText: true,
                  validator: (v) => Validators.validateConfirmPassword(v, _passwordController.text),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your account stays limited until your residency is verified.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _termsAccepted,
                  onChanged: vm.isLoading ? null : (v) => setState(() => _termsAccepted = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: const [
                        TextSpan(text: 'I agree to the '),
                        TextSpan(text: 'Terms', style: TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: ' and '),
                        TextSpan(text: 'Community Guidelines', style: TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
                if (vm.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
                CustomButton(
                  label: 'Create account',
                  isLoading: vm.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: vm.isLoading
                      ? null
                      : () {
                          vm.clearError();
                          Navigator.of(context).pop();
                        },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
