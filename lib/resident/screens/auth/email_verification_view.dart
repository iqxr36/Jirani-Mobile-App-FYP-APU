// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : email_verification_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/widgets/auth_feedback_banner.dart';
import 'package:provider/provider.dart';

const Color _brandTeal = Color(0xFF006D77);
const double _maxContentWidth = 390;

/// Email verification — Figma Group 19: illustration, card with timer + resend + copy, Continue.
// Email verification UI feature: prompts the resident to verify their Firebase email address.
class EmailVerificationView extends StatefulWidget {
  const EmailVerificationView({
    super.key,
    this.email,
    this.onVerified,
    this.onSkip,
    this.onBack,
    this.sendLinkOnOpen = false,
  });

  /// Falls back to [FirebaseAuth.instance.currentUser?.email] when null or empty.
  final String? email;

  /// Called after Firebase reports verified and Firestore is merged.
  final VoidCallback? onVerified;

  /// Called when the user chooses to verify later.
  final VoidCallback? onSkip;

  /// Called when the user taps the back chevron.
  final VoidCallback? onBack;

  /// Sends a fresh verification email as soon as this screen opens.
  final bool sendLinkOnOpen;

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _continueLoading = false;
  bool _resendLoading = false;
  String? _successBanner;
  String? _errorBanner;

  String get _displayEmail {
    final fromWidget = widget.email?.trim();
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    return FirebaseAuth.instance.currentUser?.email?.trim() ??
        'john.doe@example.com';
  }

  @override
  void initState() {
    super.initState();
    _startCountdown();
    if (widget.sendLinkOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_handleResendLink(force: true));
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Email verification UI feature: starts resend cooldown timer.
  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsRemaining <= 0) {
        t.cancel();
        setState(() {});
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  String _formatSeconds(int seconds) {
    final s = seconds.clamp(0, 3600);
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // Email verification UI feature: resends Firebase verification link after cooldown or initial open.
  Future<void> _handleResendLink({bool force = false}) async {
    if ((!force && _secondsRemaining > 0) || _resendLoading) return;
    setState(() {
      _resendLoading = true;
      _successBanner = null;
      _errorBanner = null;
    });
    try {
      final vm = context.read<AuthViewModel>();
      vm.clearError(notify: false);
      await vm.resendEmailVerification();
      if (!mounted) return;
      if (vm.errorMessage != null) {
        setState(() {
          _errorBanner = vm.errorMessage;
          _successBanner = null;
        });
        return;
      }
      setState(() {
        _successBanner = 'Link Successfully Sent';
        _errorBanner = null;
      });
      _startCountdown();
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  // Email verification UI feature: reloads auth state and continues only when email is verified.
  Future<void> _handleContinue() async {
    if (_continueLoading) return;
    setState(() {
      _continueLoading = true;
      _errorBanner = null;
    });
    try {
      final verified = await context
          .read<AuthViewModel>()
          .refreshEmailVerificationStatus();
      if (!mounted) return;
      if (!verified) {
        setState(
          () => _errorBanner =
              context.read<AuthViewModel>().errorMessage ??
              'Please verify your email before continuing.',
        );
        return;
      }

      widget.onVerified?.call();
      if (widget.onVerified == null && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) setState(() => _errorBanner = e.toString());
    } finally {
      if (mounted) setState(() => _continueLoading = false);
    }
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const Icon(Icons.chevron_left, color: _brandTeal, size: 30),
              onPressed: _continueLoading ? null : _handleBack,
            ),
          ),
          const Text(
            'Verify Email Address',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _brandTeal,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 332, maxHeight: 256),
        child: SizedBox(
          height: 240,
          width: double.infinity,
          child: Image.asset(
            'assets/auth1.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.mark_email_unread_outlined,
              size: 120,
              color: _brandTeal.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionRichText(BuildContext context) {
    final email = _displayEmail;
    return Text.rich(
      TextSpan(
        style: TextStyle(color: context.appMuted, fontSize: 14, height: 1.35),
        children: [
          const TextSpan(text: "We've sent a secure verification link to\n"),
          TextSpan(
            text: email,
            style: const TextStyle(
              color: _brandTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(
            text: '. Please click the\nlink to activate your account.',
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCard(BuildContext context) {
    final canResend = _secondsRemaining <= 0 && !_resendLoading;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.glassFill(),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.residentOutline()),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 170),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: context.appMuted.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(color: context.appMuted, fontSize: 14),
                      children: [
                        const TextSpan(text: 'Resend Link in '),
                        TextSpan(
                          text: _formatSeconds(_secondsRemaining),
                          style: const TextStyle(
                            color: _brandTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: SizedBox(
                  width: 132,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: (!canResend || _continueLoading)
                        ? null
                        : _handleResendLink,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: canResend
                          ? _brandTeal
                          : _brandTeal.withValues(alpha: 0.45),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _brandTeal.withValues(
                        alpha: 0.35,
                      ),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _resendLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Resend Link',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildInstructionRichText(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _brandTeal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _brandTeal.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _continueLoading ? null : _handleContinue,
        child: _continueLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
      ),
    );
  }

  Widget _buildSkipButton() {
    if (widget.onSkip == null) return const SizedBox.shrink();

    return TextButton(
      onPressed: _continueLoading ? null : widget.onSkip,
      style: TextButton.styleFrom(
        foregroundColor: _brandTeal,
        minimumSize: const Size.fromHeight(44),
      ),
      child: const Text(
        'Do it later',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = JiraniResponsive.bottomInset(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 0, 28, 18 + bottomInset),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        _buildHeader(),
                        const SizedBox(height: 12),
                        _buildHeroImage(),
                        const SizedBox(height: 12),
                        _buildCard(context),
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
                    constraints: const BoxConstraints(
                      maxWidth: _maxContentWidth,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        if (_successBanner != null)
                          AuthFeedbackBanner.success(_successBanner!),
                        if (_successBanner != null && _errorBanner != null)
                          const SizedBox(height: 16),
                        if (_errorBanner != null)
                          AuthFeedbackBanner.failure(_errorBanner!),
                        if (_successBanner != null || _errorBanner != null)
                          const SizedBox(height: 16),
                        _buildContinueButton(),
                        const SizedBox(height: 8),
                        _buildSkipButton(),
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
