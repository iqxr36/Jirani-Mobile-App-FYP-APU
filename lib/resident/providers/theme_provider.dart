// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : theme_provider.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme feature: stores the resident dark-mode preference and exposes the Material theme mode.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _loadPreference();
  }

  static const String _darkModeKey = 'resident_dark_theme_enabled';

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Theme feature: updates dark mode in memory and persists it to SharedPreferences.
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;

    _isDarkMode = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  // Theme feature: restores the resident dark-mode preference when the app starts.
  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }
}
