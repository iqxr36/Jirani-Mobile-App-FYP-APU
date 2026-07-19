// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_theme_data.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,10-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';

/// Builds a Material 3 theme scoped to the admin portal accent preset.
ThemeData buildAdminTheme({
  required Color primary,
  required Color secondary,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
    onSecondary: Colors.white,
    primaryContainer: primary.withValues(alpha: 0.12),
    onPrimaryContainer: primary,
    secondaryContainer: secondary.withValues(alpha: 0.22),
    onSecondaryContainer: primary,
    surface: AdminThemeTokens.surface,
    onSurface: AdminThemeTokens.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AdminThemeTokens.background,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(primary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primary;
        return null;
      }),
    ),
  );
}

/// Non-accent admin surface tokens (unchanged across presets).
class AdminThemeTokens {
  const AdminThemeTokens._();

  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1F2937);
}
