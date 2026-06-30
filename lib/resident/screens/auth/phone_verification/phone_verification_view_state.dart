part of '../phone_verification_view.dart';

// Phone verification UI feature: manages OTP entry, resend cooldown, and Firebase phone credential linking.
class _PhoneVerificationViewState extends State<PhoneVerificationView> {
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

  // Phone verification UI feature: starts the SMS resend countdown.
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

  // Phone verification UI feature: asks Firebase to send or resend an SMS verification code.
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

  // Phone verification UI feature: handles Android automatic SMS verification and links the credential.
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

  /// Registration flow uses [onFlowFinished]; profile / manual routes use [Navigator.pop].
  void _leaveScreen() {
    if (!mounted) return;
    if (widget.onFlowFinished != null) {
      widget.onFlowFinished!();
    } else {
      Navigator.of(context).pop();
    }
  }

  // Phone verification UI feature: moves focus and stores digit input across the OTP boxes.
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

  // Phone verification UI feature: spreads pasted OTP digits across remaining boxes.
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

  // Phone verification UI feature: validates OTP digits and links the phone credential to Firebase Auth.
  Future<void> _handleContinue() async {
    final codeError = Validators.validateSixDigitCode(_otpCode);
    if (!_isOtpComplete || codeError != null) {
      setState(() {
        _errorBanner = codeError ?? 'Please enter the 6-digit verification code.';
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

  // Phone verification UI feature: restarts SMS verification after resend is allowed.
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
                      maxWidth: _kMaxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 28),
                        _PhoneVerificationHeader(
                          loading: _isLoading,
                          onBack: _leaveScreen,
                        ),
                        const SizedBox(height: 45),
                        _PhoneVerificationIntro(displayPhone: _displayPhone),
                        const SizedBox(height: 32),
                        const _PhoneVerificationSecondLine(),
                        const SizedBox(height: 32),
                        _PhoneVerificationOtpCard(
                          otpControllers: _otpControllers,
                          focusNodes: _focusNodes,
                          secondsRemaining: _secondsRemaining,
                          sendingCode: _sendingCode,
                          onOtpChanged: _onOtpChanged,
                          onResend: _handleResendCode,
                        ),
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
                      maxWidth: _kMaxContentWidth,
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
                        _PhoneVerificationContinueButton(
                          enabled: _isOtpComplete &&
                              !_isLoading &&
                              !_sendingCode &&
                              _verificationId != null,
                          loading: _isLoading,
                          onPressed: _handleContinue,
                        ),
                        const SizedBox(height: 8),
                        _PhoneVerificationSkipButton(
                          visible: widget.onFlowFinished != null,
                          loading: _isLoading,
                          onPressed: _leaveScreen,
                        ),
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
