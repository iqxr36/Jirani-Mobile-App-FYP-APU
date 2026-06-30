part of '../verification_process_view.dart';

// Verification process UI feature: explains the steps required to unlock full resident access.
class VerificationProcessView extends StatelessWidget {
  const VerificationProcessView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VerificationViewModel>(
      create: (_) => VerificationViewModel()..loadCurrentRequest(),
      child: const _VerificationProcessContent(),
    );
  }
}
