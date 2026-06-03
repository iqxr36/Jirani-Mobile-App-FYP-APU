import 'package:flutter/material.dart';
import 'package:jirani/core/onboarding/resident_onboarding_prefs.dart';
import 'package:jirani/views/auth/login_view.dart';
import 'package:jirani/views/onboarding/onboarding_screen.dart';

/// Mobile-only: shows onboarding once, then [LoginView].
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_showOnboarding) {
      return OnboardingScreen(onFinished: _finishOnboarding);
    }
    return const LoginView();
  }
}
