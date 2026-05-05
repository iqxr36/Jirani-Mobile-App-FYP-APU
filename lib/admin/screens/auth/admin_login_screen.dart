import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';
import 'package:fyp_flutter_application/core/utils/validators.dart';
import 'package:fyp_flutter_application/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _localError = null);
    final auth = context.read<AuthProvider>();
    await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;

    final user = auth.currentUser;
    if (auth.errorMessage != null || user == null) {
      setState(() => _localError = auth.errorMessage);
      return;
    }

    final role = user.role;
    if (role == AppConstants.roleCommunityAdmin || role == AppConstants.roleSystemAdmin) {
      return;
    }

    await auth.logout();
    if (!mounted) return;
    if (role == AppConstants.roleResident) {
      setState(() {
        _localError =
            'This account is a resident account. Please sign in through the Resident Mobile App.';
      });
    } else {
      setState(() => _localError = 'Admin role not found for this account.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWide = MediaQuery.of(context).size.width >= 900;

    final loginCard = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Trust Community Admin',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Management verification portal',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 12),
                if (_localError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_localError!, style: const TextStyle(color: Colors.red)),
                  ),
                FilledButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
                TextButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          final email = _emailCtrl.text.trim();
                          if (email.isEmpty) {
                            setState(() => _localError = 'Enter your email to reset password.');
                            return;
                          }
                          await auth.sendPasswordResetEmail(email);
                          if (!mounted) return;
                          if (auth.errorMessage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password reset email sent.')),
                            );
                          } else {
                            setState(() => _localError = auth.errorMessage);
                          }
                        },
                  child: const Text('Forgot password?'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This portal is restricted to authorized community administrators only.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Resident users should use the mobile app.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  Expanded(
                    child: Container(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                      padding: const EdgeInsets.all(40),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Secure Admin Access\nfor ${AppConstants.appName}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(child: loginCard),
                  ),
                ],
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: loginCard,
                ),
              ),
      ),
    );
  }
}
