import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/theme/admin_theme_preset.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Admin theme feature: persists the admin portal accent color preset.
class AdminThemeProvider extends ChangeNotifier {
  AdminThemeProvider() {
    _loadPreference();
  }

  static const String _prefsKey = 'admin_theme_preset_id';

  String _presetId = AdminThemePreset.teal.id;

  String get presetId => _presetId;

  AdminThemePreset get preset => AdminThemePreset.byId(_presetId);

  List<AdminThemePreset> get presets => AdminThemePreset.all;

  Future<void> setPreset(String id) async {
    if (_presetId == id) return;
    _presetId = id;
    AdminColors.applyPreset(AdminThemePreset.byId(id));
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id);
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _presetId = prefs.getString(_prefsKey) ?? AdminThemePreset.teal.id;
    AdminColors.applyPreset(AdminThemePreset.byId(_presetId));
    notifyListeners();
  }
}
