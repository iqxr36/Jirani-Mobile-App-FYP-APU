import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/theme/admin_theme_preset.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Admin theme feature: persists the admin portal accent color preset.
class AdminThemeProvider extends ChangeNotifier {
  AdminThemeProvider() {
    _loadLocalFallback();
  }

  static const String _prefsKey = 'admin_theme_preset_id';

  String _presetId = AdminThemePreset.teal.id;
  bool _hasAuthoritativeProfileTheme = false;

  String get presetId => _presetId;

  AdminThemePreset get preset => AdminThemePreset.byId(_presetId);

  List<AdminThemePreset> get presets => AdminThemePreset.all;

  Future<void> setPreset(String id) async {
    await _applyPreset(id, persistLocal: true);
  }

  /// Applies the theme stored on admins/{uid}; wins over local SharedPreferences.
  Future<void> syncFromAdminProfile(String themePresetId) async {
    _hasAuthoritativeProfileTheme = true;
    await _applyPreset(
      themePresetId,
      persistLocal: true,
      alwaysApplyColors: true,
    );
  }

  void clearAuthoritativeProfileTheme() {
    _hasAuthoritativeProfileTheme = false;
  }

  Future<void> _loadLocalFallback() async {
    final prefs = await SharedPreferences.getInstance();
    if (_hasAuthoritativeProfileTheme) return;

    final preset = AdminThemePreset.byId(
      prefs.getString(_prefsKey) ?? AdminThemePreset.teal.id,
    );
    _presetId = preset.id;
    AdminColors.applyPreset(preset);
    notifyListeners();
  }

  Future<void> _applyPreset(
    String id, {
    required bool persistLocal,
    bool alwaysApplyColors = false,
  }) async {
    final preset = AdminThemePreset.byId(id);
    if (_presetId == preset.id && !alwaysApplyColors) return;

    _presetId = preset.id;
    AdminColors.applyPreset(preset);
    notifyListeners();

    if (persistLocal) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, preset.id);
    }
  }
}
