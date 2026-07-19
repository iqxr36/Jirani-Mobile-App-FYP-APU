// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : login_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Tuesday,05-May-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/core/utils/auth_debug_log.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/resident/screens/auth/forgot_password_view.dart';
import 'package:jirani/resident/screens/auth/register_view.dart';
import 'package:jirani/shared/widgets/jirani_logo.dart';
import 'package:provider/provider.dart';

/// Resident login - Jirani (Figma Group 13).
/// Brand teal: #006D77
const Color _kBrandTeal = Color(0xFF006D77);
const double _kCardMaxWidth = 390;
const double _kFieldRadius = 11;

// Resident authentication UI feature: email/password and social sign-in screen.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  static Color _fieldBorderColor(BuildContext context) =>
      context.residentOutline();

  OutlineInputBorder _outlineBorder(
    BuildContext context, {
    bool focused = false,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kFieldRadius),
      borderSide: BorderSide(
        color: focused ? _kBrandTeal : _fieldBorderColor(context),
        width: focused ? 1.5 : 1,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Resident authentication UI feature: validates and submits email/password login.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    authDebugLog('[ResidentLoginView] Login button pressed');
    authDebugLog('[ResidentLoginView] login call started');
    await context.read<AuthViewModel>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    authDebugLog('[ResidentLoginView] login call finished');
    if (!mounted) return;
    final vm = context.read<AuthViewModel>();
    if (vm.errorMessage != null) {
      authDebugLog('[ResidentLoginView] login failed');
    }
  }

  // Resident authentication UI feature: starts Google sign-in and lets AuthWrapper route the authenticated user.
  Future<void> _googleSignIn() async {
    await context.read<AuthViewModel>().signInWithGoogle();
  }

  static TextStyle _labelStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w600,
      color: context.appInk,
      fontSize: 13,
    );
  }

  static TextStyle _hintStyle(BuildContext context) {
    return TextStyle(
      color: context.appMuted.withValues(alpha: 0.72),
      fontSize: 15,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final dividerGrey = context.residentOutline();
    final bottomInset = JiraniResponsive.bottomInset(context);

    final baseDecoration = InputDecoration(
      filled: true,
      fillColor: context.isDarkUi
          ? context.residentScheme.surfaceContainerHighest
          : Colors.white,
      hintStyle: _hintStyle(context),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: _outlineBorder(context),
      enabledBorder: _outlineBorder(context),
      focusedBorder: _outlineBorder(context, focused: true),
      errorBorder: _outlineBorder(context),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kFieldRadius),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final topPad = h > 600 ? h * 0.06 : 24.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, topPad, 20, 24 + bottomInset),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _kCardMaxWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: JiraniLogo(height: 88)),
                        const SizedBox(height: 14),
                        Text(
                          'Welcome to your Community!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _kBrandTeal,
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                              ),
                        ),
                        const SizedBox(height: 20),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.glassFill(),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: dividerGrey),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 22,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Email Address',
                                  style: _labelStyle(context),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: baseDecoration.copyWith(
                                    hintText: 'example@gmail.com',
                                  ),
                                  validator: Validators.validateEmail,
                                  enabled: !vm.isLoading,
                                ),
                                const SizedBox(height: 18),
                                Text('Password', style: _labelStyle(context)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: baseDecoration.copyWith(
                                    hintText: '************',
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? 'Show password'
                                          : 'Hide password',
                                      onPressed: vm.isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: context.appMuted,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  validator: Validators.validatePassword,
                                  enabled: !vm.isLoading,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: _kBrandTeal,
                                    ),
                                    onPressed: vm.isLoading
                                        ? null
                                        : () {
                                            vm.clearError();
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    const ForgotPasswordView(),
                                              ),
                                            );
                                          },
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Divider(height: 1, thickness: 1, color: dividerGrey),
                        const SizedBox(height: 16),
                        Text(
                          'Or continue with',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: _kBrandTeal,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _GoogleSignInButton(
                          onPressed: vm.isLoading ? null : _googleSignIn,
                        ),
                        const SizedBox(height: 28),
                        if (vm.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              vm.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        SizedBox(
                          height: 44,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: _kBrandTeal,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _kBrandTeal.withValues(
                                alpha: 0.6,
                              ),
                              disabledForegroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: vm.isLoading ? null : _submit,
                            child: vm.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Don\'t have an account?',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: context.appInk),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: _kBrandTeal,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: vm.isLoading
                              ? null
                              : () {
                                  vm.clearError();
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const RegisterView(),
                                    ),
                                  );
                                },
                          child: const Text(
                            'Create an account',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return Opacity(
      opacity: isEnabled ? 1 : 0.62,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Tooltip(
            message: 'Continue with Google',
            child: SizedBox(
              width: 47,
              height: 47,
              child: Center(
                child: Image.asset(
                  'assets/images/auth/google_g.png',
                  width: 40,
                  height: 40,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
