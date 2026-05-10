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
