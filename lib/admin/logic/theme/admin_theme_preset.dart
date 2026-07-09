import 'package:flutter/material.dart';

/// Admin portal accent presets — primary/secondary drive buttons, nav, and hero UI.
class AdminThemePreset {
  const AdminThemePreset({
    required this.id,
    required this.label,
    required this.primary,
    required this.secondary,
  });

  final String id;
  final String label;
  final Color primary;
  final Color secondary;

  static const teal = AdminThemePreset(
    id: 'teal',
    label: 'Teal',
    primary: Color(0xFF006D77),
    secondary: Color(0xFF83C5BE),
  );

  static const darkPurple = AdminThemePreset(
    id: 'darkPurple',
    label: 'Dark purple',
    primary: Color(0xFF5B21B6),
    secondary: Color(0xFFC4B5FD),
  );

  static const maroon = AdminThemePreset(
    id: 'maroon',
    label: 'Maroon',
    primary: Color(0xFF7F1D1D),
    secondary: Color(0xFFFCA5A5),
  );

  static const darkBlue = AdminThemePreset(
    id: 'darkBlue',
    label: 'Dark blue',
    primary: Color(0xFF1E3A8A),
    secondary: Color(0xFF93C5FD),
  );

  static const List<AdminThemePreset> all = [
    teal,
    darkPurple,
    maroon,
    darkBlue,
  ];

  static AdminThemePreset byId(String id) {
    return all.firstWhere(
      (preset) => preset.id == id,
      orElse: () => teal,
    );
  }
}
