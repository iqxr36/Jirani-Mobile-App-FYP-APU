// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : verification_process_view_main.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

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
