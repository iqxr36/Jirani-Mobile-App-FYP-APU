part of '../phone_verification_view.dart';

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
