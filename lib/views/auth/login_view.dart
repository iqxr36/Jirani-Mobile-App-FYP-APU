import 'package:flutter/material.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/viewmodels/auth_viewmodel.dart';
import 'package:jirani/views/auth/forgot_password_view.dart';
import 'package:jirani/views/auth/register_view.dart';
import 'package:jirani/shared/widgets/jirani_logo.dart';
import 'package:provider/provider.dart';

/// Resident login - Jirani (Figma Group 13).
/// Brand teal: #006D77
const Color _kBrandTeal = Color(0xFF006D77);
const double _kCardMaxWidth = 350;
const double _kBorderOpacity = 0.2;
const double _kFieldRadius = 11;

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

  static Color _fieldBorderColor() => Colors.grey.shade300;

  OutlineInputBorder _outlineBorder({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kFieldRadius),
      borderSide: BorderSide(
        color: focused ? _kBrandTeal : _fieldBorderColor(),
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

  Future<void> _googleSignIn() async {
    await context.read<AuthViewModel>().signInWithGoogle();
  }

  Future<void> _appleSignIn() async {
    await context.read<AuthViewModel>().signInWithApple();
  }

  static TextStyle _labelStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w600,
      color: Colors.black,
      fontSize: 13,
    );
  }

  static TextStyle _hintStyle() {
    return TextStyle(color: Colors.black.withValues(alpha: 0.35), fontSize: 15);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final dividerGrey = Colors.black.withValues(alpha: _kBorderOpacity);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final baseDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintStyle: _hintStyle(),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: _outlineBorder(),
      enabledBorder: _outlineBorder(),
      focusedBorder: _outlineBorder(focused: true),
      errorBorder: _outlineBorder(),
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
                            color: Colors.white,
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
                                        color: Colors.black.withValues(
                                          alpha: 0.45,
                                        ),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialIconButton(
                              tooltip: 'Continue with Apple',
                              onPressed: vm.isLoading ? null : _appleSignIn,
                              child: const _AppleSignInIcon(),
                            ),
                            Container(
                              width: 1,
                              height: 59,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              color: dividerGrey,
                            ),
                            _SocialIconButton(
                              tooltip: 'Continue with Google',
                              onPressed: vm.isLoading ? null : _googleSignIn,
                              child: const _GoogleSignInIcon(),
                            ),
                          ],
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
                              ?.copyWith(color: Colors.black87),
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

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(width: 47, height: 47, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _AppleSignInIcon extends StatelessWidget {
  const _AppleSignInIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.apple, color: Colors.black, size: 36);
  }
}

/// Prefer `assets/images/auth/google.png` when added to pubspec.
class _GoogleSignInIcon extends StatelessWidget {
  const _GoogleSignInIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4285F4),
            height: 1,
          ),
        ),
      ),
    );
  }
}
