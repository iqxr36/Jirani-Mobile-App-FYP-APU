part of '../verification_process_view.dart';

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
