import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/core/utils/validators.dart';
import 'package:fyp_flutter_application/viewmodels/auth_viewmodel.dart';
import 'package:fyp_flutter_application/views/auth/forgot_password_view.dart';
import 'package:fyp_flutter_application/views/auth/register_view.dart';
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
    debugPrint('[ResidentLoginView] Login button pressed');
    debugPrint('[ResidentLoginView] Email: ${_emailController.text.trim()}');

    debugPrint('[ResidentLoginView] login call started');
    await context.read<AuthViewModel>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    debugPrint('[ResidentLoginView] login call finished');
    if (!mounted) return;
    final vm = context.read<AuthViewModel>();
    if (vm.errorMessage != null) {
      debugPrint('[ResidentLoginView] login error: ${vm.errorMessage}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Icon(Icons.groups_2_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  AppConstants.appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Share safely with verified neighbors',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 28),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: vm.isLoading
                        ? null
                        : () {
                            vm.clearError();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const ForgotPasswordView()),
                            );
                          },
                    child: const Text('Forgot password?'),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.security_outlined, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Only verified residents can access full community features. '
                            'You can still sign in and explore limited areas while verification is pending.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (vm.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
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
                            MaterialPageRoute<void>(builder: (_) => const RegisterView()),
                          );
                        },
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
