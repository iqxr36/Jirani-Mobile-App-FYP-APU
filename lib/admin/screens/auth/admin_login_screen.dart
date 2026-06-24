import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/shared/providers/auth_provider.dart';
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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _localError = null);
    debugPrint(
      '[AdminLoginScreen] login button pressed email=${_emailCtrl.text.trim()}',
    );
    final auth = context.read<AuthProvider>();
    debugPrint('[AdminLoginScreen] login call started');
    await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    debugPrint('[AdminLoginScreen] login call finished');
    if (!mounted) return;

    final admin = auth.currentAdmin;
    final user = auth.currentUser;
    if (auth.errorMessage != null || (admin == null && user == null)) {
      debugPrint('[AdminLoginScreen] login error=${auth.errorMessage}');
      setState(() => _localError = auth.errorMessage);
      return;
    }

    if (admin != null) {
      return;
    }

    await auth.logout();
    if (!mounted) return;
    final role = user?.role ?? '';
    if (role == AppConstants.roleCommunityAdmin ||
        role == AppConstants.roleSystemAdmin) {
      setState(() {
        _localError =
            'This account has an old admin role in users. Create an admins/${user?.uid} document and assign its community there.';
      });
      return;
    }
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

    final loginCard = Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF006D77).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/In-app-logo-Jirani.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.apartment_rounded,
                    color: Color(0xFF006D77),
                    size: 34,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Jirani Admin',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Secure community management portal',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordCtrl,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!auth.isLoading) _submit();
              },
              validator: Validators.validatePassword,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: auth.isLoading ? null : () => _sendResetEmail(auth),
                child: const Text('Forgot Password?'),
              ),
            ),
            if (_localError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE29578).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE29578).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFE29578),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _localError!,
                          style: const TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF006D77),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: auth.isLoading ? null : _submit,
              icon: auth.isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(auth.isLoading ? 'Signing in...' : 'Login'),
            ),
            const SizedBox(height: 18),
            const Divider(color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            const Text(
              'This portal is restricted to authorized community administrators only.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 6),
            Text(
              'Resident users should use the mobile app.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF006D77), Color(0xFF83C5BE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Text(
                      'Secure Admin Access for ${AppConstants.appName}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  loginCard,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendResetEmail(AuthProvider auth) async {
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
  }
}
