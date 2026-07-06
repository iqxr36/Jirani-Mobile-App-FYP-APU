import 'package:flutter/material.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/core/utils/validators.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/widgets/auth_feedback_banner.dart';
import 'package:provider/provider.dart';

/// Forgot password — Figma reset screen: header, card, success/error banners, bottom buttons.
// Password reset UI feature: lets a resident request a Firebase password reset email.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  static const Color _kBrandTeal = Color(0xFF006D77);
  static const double _kCardRadius = 26;
  static const double _kFieldRadius = 10;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  // Password reset UI feature: clears the sent-state when the email field changes.
  void _onEmailChanged() {
    if (!mounted) return;
    context.read<AuthViewModel>().clearError();
    if (_emailSent) setState(() => _emailSent = false);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    super.dispose();
  }

  // Password reset UI feature: validates the email and sends the reset link.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<AuthViewModel>();
    vm.clearError();
    await vm.sendPasswordResetEmail(_emailController.text.trim());

    if (!mounted) return;
    if (vm.errorMessage == null) {
      setState(() => _emailSent = true);
    }
  }

  InputDecoration _emailDecoration(BuildContext context) {
    return InputDecoration(
      hintText: 'example@gmail.com',
      filled: true,
      fillColor: context.isDarkUi
          ? context.residentScheme.surfaceContainerHighest
          : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: TextStyle(
        color: context.appMuted.withValues(alpha: 0.72),
        fontSize: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kFieldRadius),
        borderSide: BorderSide(color: context.residentOutline(lightAlpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kFieldRadius),
        borderSide: const BorderSide(color: _kBrandTeal, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kFieldRadius),
        borderSide: BorderSide(
          color: AuthFeedbackBanner.errorRed.withValues(alpha: 0.8),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kFieldRadius),
        borderSide: BorderSide(color: AuthFeedbackBanner.errorRed, width: 1.3),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthViewModel vm) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: _kBrandTeal,
              ),
              onPressed: vm.isLoading
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
          ),
          Text(
            'Forgot Password?',
            textAlign: TextAlign.center,
            style:
                Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _kBrandTeal,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ) ??
                const TextStyle(
                  color: _kBrandTeal,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(BuildContext context, AuthViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.appInk,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enabled: !vm.isLoading,
          style: TextStyle(fontSize: 15, color: context.appInk),
          decoration: _emailDecoration(context),
          validator: Validators.validateEmail,
        ),
      ],
    );
  }

  Widget _buildResetCard(BuildContext context, AuthViewModel vm) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.glassFill(),
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 15),
              const Text(
                'Hang Tight!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _kBrandTeal,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Enter your email address and we will send a password reset link to you.',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: context.appInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 62),
              _buildEmailField(context, vm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendResetButton(AuthViewModel vm) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _kBrandTeal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kBrandTeal.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                'Send Reset Link',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildReturnToLoginButton(AuthViewModel vm) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.black.withValues(alpha: 0.16),
          foregroundColor: _kBrandTeal,
          disabledForegroundColor: _kBrandTeal.withValues(alpha: 0.5),
          disabledBackgroundColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: vm.isLoading ? null : () => Navigator.of(context).pop(),
        child: const Text(
          'Return to Login',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final bottomInset = JiraniResponsive.bottomInset(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 0, 28, 20 + bottomInset),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context, vm),
                        const SizedBox(height: 12),
                        _buildResetCard(context, vm),
                        const SizedBox(height: 28),
                        if (_emailSent)
                          AuthFeedbackBanner.success(
                            'Password reset email sent!',
                          ),
                        if (vm.errorMessage != null) ...[
                          if (_emailSent) const SizedBox(height: 16),
                          AuthFeedbackBanner.failure(vm.errorMessage!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSendResetButton(vm),
                        const SizedBox(height: 12),
                        _buildReturnToLoginButton(vm),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
