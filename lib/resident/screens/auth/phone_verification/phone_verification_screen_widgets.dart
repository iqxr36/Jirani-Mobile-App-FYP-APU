part of '../phone_verification_view.dart';

class _PhoneVerificationHeader extends StatelessWidget {
  const _PhoneVerificationHeader({
    required this.loading,
    required this.onBack,
  });

  final bool loading;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
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
              icon: const Icon(Icons.chevron_left, color: _kBrandTeal, size: 28),
              onPressed: loading ? null : onBack,
            ),
          ),
          const Text(
            'Verify Phone Number',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kBrandTeal,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneVerificationIntro extends StatelessWidget {
  const _PhoneVerificationIntro({required this.displayPhone});

  final String displayPhone;

  @override
  Widget build(BuildContext context) {
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
            text: displayPhone,
            style: const TextStyle(
              color: _kBrandTeal,
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
}

class _PhoneVerificationSecondLine extends StatelessWidget {
  const _PhoneVerificationSecondLine();

  @override
  Widget build(BuildContext context) {
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
}

class _PhoneVerificationContinueButton extends StatelessWidget {
  const _PhoneVerificationContinueButton({
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
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
        onPressed: !enabled ? null : onPressed,
        child: loading
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
}

class _PhoneVerificationSkipButton extends StatelessWidget {
  const _PhoneVerificationSkipButton({
    required this.visible,
    required this.loading,
    required this.onPressed,
  });

  final bool visible;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return TextButton(
      onPressed: loading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: _kBrandTeal,
        minimumSize: const Size.fromHeight(44),
      ),
      child: const Text(
        'Do it later',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
