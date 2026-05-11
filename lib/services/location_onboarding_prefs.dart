import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the resident has completed the first-run location onboarding screen.
class LocationOnboardingPrefs {
  LocationOnboardingPrefs._();

  static const _kKey = 'trust_community_location_onboarding_shown_v1';

  static Future<bool> wasShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kKey) ?? false;
  }

  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, true);
  }
}
