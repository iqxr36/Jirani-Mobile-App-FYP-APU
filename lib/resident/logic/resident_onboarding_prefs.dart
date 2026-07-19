// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : resident_onboarding_prefs.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether resident onboarding has been completed (mobile only).
class ResidentOnboardingPrefs {
  ResidentOnboardingPrefs._();

  static const String _key = 'resident_onboarding_v1_complete';

  static Future<bool> isComplete() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key) ?? false;
  }

  static Future<void> markComplete() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, true);
  }
}
