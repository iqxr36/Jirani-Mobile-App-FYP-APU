import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/utils/validators.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/views/home/home_view.dart';
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
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<AuthViewModel>().register(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    final vm = context.read<AuthViewModel>();
    if (vm.errorMessage == null && vm.currentUser != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeView()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _fullNameController,
                labelText: 'Full Name',
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
                controller: _passwordController,
                labelText: 'Password',
                obscureText: true,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 16),
              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    vm.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              CustomButton(
                label: 'Register',
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
    );
  }
}
