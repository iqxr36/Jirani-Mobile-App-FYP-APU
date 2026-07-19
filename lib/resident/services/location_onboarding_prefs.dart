// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : location_onboarding_prefs.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

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
