part of '../phone_verification_view.dart';

class _PhoneVerificationOtpRow extends StatelessWidget {
  const _PhoneVerificationOtpRow({
    required this.maxWidth,
    required this.otpControllers,
    required this.focusNodes,
    required this.onOtpChanged,
  });

  final double maxWidth;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onOtpChanged;

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    final raw = (maxWidth - 5 * gap) / 6;
    final boxW = raw.clamp(36.0, 42.0).toDouble();
    const boxH = 34.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: boxW,
          height: boxH,
          child: TextField(
            controller: otpControllers[index],
            focusNode: focusNodes[index],
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
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
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
                borderSide: const BorderSide(color: _kBrandTeal, width: 1.2),
              ),
            ),
            onChanged: (v) => onOtpChanged(index, v),
            onSubmitted: (_) {
              if (index < 5) focusNodes[index + 1].requestFocus();
            },
            buildCounter:
                (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
          ),
        );
      }),
    );
  }
}

class _PhoneVerificationOtpCard extends StatelessWidget {
  const _PhoneVerificationOtpCard({
    required this.otpControllers,
    required this.focusNodes,
    required this.secondsRemaining,
    required this.sendingCode,
    required this.onOtpChanged,
    required this.onResend,
  });

  final List<TextEditingController> otpControllers;
  final List<FocusNode> focusNodes;
  final int secondsRemaining;
  final bool sendingCode;
  final void Function(int index, String value) onOtpChanged;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
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
                        color: _kBrandTeal,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PhoneVerificationOtpRow(
                    maxWidth: constraints.maxWidth,
                    otpControllers: otpControllers,
                    focusNodes: focusNodes,
                    onOtpChanged: onOtpChanged,
                  ),
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
                                secondsRemaining.clamp(0, 3600),
                              ),
                              style: const TextStyle(
                                color: _kBrandTeal,
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
                        onPressed: sendingCode ? null : onResend,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: secondsRemaining > 0
                              ? _kBrandTeal.withValues(alpha: 0.75)
                              : _kBrandTeal,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _kBrandTeal.withValues(
                            alpha: 0.45,
                          ),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: sendingCode
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
}
