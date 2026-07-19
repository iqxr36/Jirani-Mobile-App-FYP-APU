// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : verification_permission_prefs.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks verification permission education screens that should appear once per install.
class VerificationPermissionPrefs {
  VerificationPermissionPrefs._();

  static const _kLocationKey =
      'trust_community_verification_location_permission_shown_v1';
  static const _kCameraKey =
      'trust_community_verification_camera_permission_shown_v1';
  static const _kPhotosDocumentsKey =
      'trust_community_verification_photos_documents_permission_shown_v1';

  static Future<bool> wasLocationShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLocationKey) ?? false;
  }

  static Future<bool> wasCameraShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kCameraKey) ?? false;
  }

  static Future<bool> wasPhotosDocumentsShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPhotosDocumentsKey) ?? false;
  }

  static Future<void> markLocationShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLocationKey, true);
  }

  static Future<void> markCameraShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCameraKey, true);
  }

  static Future<void> markPhotosDocumentsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPhotosDocumentsKey, true);
  }
}
