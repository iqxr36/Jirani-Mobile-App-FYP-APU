// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : resident_pre_auth_gate.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:jirani/resident/logic/resident_onboarding_prefs.dart';
import 'package:jirani/resident/screens/auth/login_view.dart';
import 'package:jirani/resident/screens/onboarding/onboarding_screen.dart';

/// Mobile-only: shows onboarding once, then [LoginView].
// Resident onboarding feature: decides whether to show onboarding before login/register screens.
class ResidentPreAuthGate extends StatefulWidget {
  const ResidentPreAuthGate({super.key});

  @override
  State<ResidentPreAuthGate> createState() => _ResidentPreAuthGateState();
}

class _ResidentPreAuthGateState extends State<ResidentPreAuthGate> {
  bool _loading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Resident onboarding feature: reads local onboarding preference before showing authentication.
  Future<void> _load() async {
    try {
      final done = await ResidentOnboardingPrefs.isComplete();
      if (!mounted) return;
      setState(() {
        _showOnboarding = !done;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _showOnboarding = false;
        _loading = false;
      });
    }
  }

  // Resident onboarding feature: marks onboarding seen and shows the pre-auth screen.
  Future<void> _finishOnboarding() async {
    try {
      await ResidentOnboardingPrefs.markComplete();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_showOnboarding) {
      return OnboardingScreen(onFinished: _finishOnboarding);
    }
    return const LoginView();
  }
}
