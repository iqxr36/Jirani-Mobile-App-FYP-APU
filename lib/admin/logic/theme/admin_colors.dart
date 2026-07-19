// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_colors.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/theme/admin_theme_preset.dart';

class AdminColors {
  const AdminColors._();

  static AdminThemePreset _preset = AdminThemePreset.teal;

  static void applyPreset(AdminThemePreset preset) {
    _preset = preset;
  }

  static Color get primary => _preset.primary;
  static Color get secondary => _preset.secondary;

  static const accent = Color(0xFFE29578);
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const success = Color(0xFF2F855A);
  static const warning = Color(0xFFB7791F);
  static const danger = Color(0xFFB42318);
}
