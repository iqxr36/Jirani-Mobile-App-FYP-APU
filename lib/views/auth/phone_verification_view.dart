import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jirani/core/theme/resident_surface_tokens.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/shared/widgets/auth_feedback_banner.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';

const Color _brandTeal = Color(0xFF006D77);
const double _maxContentWidth = 390;

/// SMS OTP entry after registration - Figma Group 18.
///
/// When [verificationId] is set, [AuthViewModel.tryLinkPhoneWithSmsCode] runs on Continue.
/// Otherwise shows a non-crashing placeholder until Firebase Phone Auth is wired
/// (e.g. call `verifyPhoneNumber` during registration and pass [verificationId] / [resendToken] here).
class PhoneVerificationView extends StatefulWidget {
  const PhoneVerificationView({
    super.key,
    required this.phoneNumber,
    this.verificationId,
    this.resendToken,
    this.onFlowFinished,
  });

  final String phoneNumber;
  final String? verificationId;
  final int? resendToken;

  /// Called after successful SMS verification, or when user taps back to skip this step.
  final VoidCallback? onFlowFinished;

  @override
  State<PhoneVerificationView> createState() => _PhoneVerificationViewState();
}

class _PhoneVerificationViewState extends State<PhoneVerificationView> {
  static const String _kFallbackDisplayPhone = '+60 12- 345 6789';

  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _focusNodes;
  Timer? _timer;
  String? _verificationId;
  int? _resendToken;
  int _secondsRemaining = 60;
  bool _isLoading = false;
  bool _sendingCode = false;
  String? _successBanner;
  String? _errorBanner;

  String get _displayPhone {
    final p = widget.phoneNumber.trim();
    return p.isEmpty ? _kFallbackDisplayPhone : p;
  }

  bool get _isOtpComplete =>
      _otpControllers.every((c) => c.text.trim().length == 1) &&
      _otpControllers.fold<int>(0, (n, c) => n + c.text.trim().length) == 6;

  String get _otpCode => _otpControllers.map((c) => c.text.trim()).join();

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
    _startCountdown();
    if ((_verificationId ?? '').isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_requestCode());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

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

  Future<void> _requestCode({bool forceResend = false}) async {
    final phone = widget.phoneNumber.trim();
    if (phone.isEmpty) {
      setState(() {
        _errorBanner = 'Phone number is missing.';
        _successBanner = null;
      });
      return;
    }
    if (_sendingCode) return;

    setState(() {
      _sendingCode = true;
      _errorBanner = null;
      if (forceResend) _successBanner = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResend ? _resendToken : null,
        verificationCompleted: (credential) {
          unawaited(_handleAutoVerifiedCredential(credential));
        },
        verificationFailed: (error) {
          if (!mounted) return;
          setState(() {
            _sendingCode = false;
            _errorBanner = error.message ?? 'Could not send verification code.';
            _successBanner = null;
          });
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _sendingCode = false;
            _successBanner = forceResend
                ? 'Code Successfully Sent'
                : 'Verification code sent.';
            _errorBanner = null;
          });
          _startCountdown();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _sendingCode = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sendingCode = false;
        _errorBanner = e.toString().replaceFirst('Exception: ', '');
        _successBanner = null;
      });
    }
  }

  Future<void> _handleAutoVerifiedCredential(
    PhoneAuthCredential credential,
  ) async {
    if (!mounted || _isLoading) return;
    setState(() {
      _isLoading = true;
      _errorBanner = null;
      _successBanner = 'Phone verified automatically.';
    });

    final vm = context.read<AuthViewModel>();
    final err = await vm.tryLinkPhoneWithCredential(
      credential: credential,
      phoneNumber: widget.phoneNumber,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _errorBanner = err;
        _successBanner = null;
        _isLoading = false;
      });
      return;
    }
    _leaveScreen();
  }

  String _formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Registration flow uses [onFlowFinished]; profile / manual routes use [Navigator.pop].
  void _leaveScreen() {
    if (!mounted) return;
    if (widget.onFlowFinished != null) {
      widget.onFlowFinished!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onOtpChanged(int index, String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length > 1) {
      _distributeFromIndex(index, digitsOnly);
      setState(() {
        if (_errorBanner != null) _errorBanner = null;
      });
      return;
    }

    if (raw.isEmpty || digitsOnly.isEmpty) {
      _otpControllers[index].clear();
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      setState(() {
        if (_errorBanner != null) _errorBanner = null;
      });
      return;
    }

    final ch = digitsOnly;
    _otpControllers[index].text = ch;
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    setState(() {
      if (_errorBanner != null) _errorBanner = null;
    });
  }

  void _distributeFromIndex(int start, String digits) {
    final chars = digits.split('');
    for (var i = 0; i < chars.length && start + i < 6; i++) {
      _otpControllers[start + i].text = chars[i];
    }
    final filled = start + chars.length;
    if (filled < 6) {
      _focusNodes[filled].requestFocus();
    } else {
      _focusNodes[5].unfocus();
    }
  }

  Future<void> _handleContinue() async {
    if (!_isOtpComplete) {
      setState(() {
        _errorBanner = 'Please enter the 6-digit verification code.';
        _successBanner = null;
      });
      return;
    }

    final vid = _verificationId?.trim();
    if (vid == null || vid.isEmpty) {
      setState(() {
        _errorBanner = _sendingCode
            ? 'Please wait while we send your code.'
            : 'Request a verification code before continuing.';
        _successBanner = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorBanner = null;
    });
    try {
      final vm = context.read<AuthViewModel>();
      final err = await vm.tryLinkPhoneWithSmsCode(
        verificationId: vid,
        smsCode: _otpCode,
        phoneNumber: widget.phoneNumber,
      );
      if (!mounted) return;
      if (err != null) {
        setState(() {
          _errorBanner = err;
          _successBanner = null;
        });
        return;
      }
      _leaveScreen();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorBanner = e.toString();
          _successBanner = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResendCode() async {
    if (_secondsRemaining > 0) {
      setState(() {
        _errorBanner = 'Please wait before requesting another code.';
        _successBanner = null;
      });
      return;
    }
    await _requestCode(forceResend: true);
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: const Icon(Icons.chevron_left, color: _brandTeal, size: 28),
              onPressed: _isLoading ? null : _leaveScreen,
            ),
          ),
          const Text(
            'Verify Phone Number',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _brandTeal,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroRichText(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          color: context.appInk,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        children: [
          const TextSpan(text: "We've sent a 6-digit verification code\nto "),
          TextSpan(
            text: _displayPhone,
            style: const TextStyle(
              color: _brandTeal,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSecondLine(BuildContext context) {
    return Text(
      'Please enter it below to secure your\naccount.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: context.appInk,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
    );
  }

  Widget _buildOtpRow(BuildContext context, double maxWidth) {
    const gap = 8.0;
    final raw = (maxWidth - 5 * gap) / 6;
    final boxW = raw.clamp(36.0, 42.0).toDouble();
    final boxH = 34.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: boxW,
          height: boxH,
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: index < 5
                ? TextInputAction.next
                : TextInputAction.done,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.appInk,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              filled: true,
              fillColor: context.isDarkUi
                  ? context.residentScheme.surfaceContainerHighest
                  : Colors.white,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: context.residentOutline()),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: context.residentOutline()),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _brandTeal, width: 1.2),
              ),
            ),
            onChanged: (v) => _onOtpChanged(index, v),
            onSubmitted: (_) {
              if (index < 5) _focusNodes[index + 1].requestFocus();
            },
            buildCounter:
                (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
          ),
        );
      }),
    );
  }

  Widget _buildOtpCard(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.glassFill(),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.residentOutline()),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 270),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: context.skeletonBar,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: _brandTeal,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildOtpRow(context, constraints.maxWidth),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: context.appMuted.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 6),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: context.appMuted,
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(text: 'Resend Code in '),
                            TextSpan(
                              text: _formatSeconds(
                                _secondsRemaining.clamp(0, 3600),
                              ),
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
                  const SizedBox(height: 35),
                  Center(
                    child: SizedBox(
                      width: 132,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isLoading || _sendingCode
                            ? null
                            : _handleResendCode,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: _secondsRemaining > 0
                              ? _brandTeal.withValues(alpha: 0.75)
                              : _brandTeal,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _brandTeal.withValues(
                            alpha: 0.45,
                          ),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _sendingCode
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "Didn't receive a code? Check your SMS\nsettings or try again later.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appMuted,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final enabled =
        _isOtpComplete &&
        !_isLoading &&
        !_sendingCode &&
        _verificationId != null;
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _brandTeal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _brandTeal.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: !enabled ? null : _handleContinue,
        child: _isLoading
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
    if (widget.onFlowFinished == null) return const SizedBox.shrink();

    return TextButton(
      onPressed: _isLoading ? null : _leaveScreen,
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
                        const SizedBox(height: 28),
                        _buildHeader(),
                        const SizedBox(height: 45),
                        _buildIntroRichText(context),
                        const SizedBox(height: 32),
                        _buildSecondLine(context),
                        const SizedBox(height: 32),
                        _buildOtpCard(context),
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
