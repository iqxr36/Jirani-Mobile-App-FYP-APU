import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/utils/validators.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/views/auth/register_view.dart';
import 'package:fyp_flutter_application/views/home/home_view.dart';
import 'package:fyp_flutter_application/widgets/custom_button.dart';
import 'package:fyp_flutter_application/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<AuthViewModel>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    final vm = context.read<AuthViewModel>();
    if (vm.errorMessage == null && vm.currentUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                label: 'Login',
                isLoading: vm.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: vm.isLoading
                    ? null
                    : () {
                        vm.clearError();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterView()),
                        );
                      },
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
