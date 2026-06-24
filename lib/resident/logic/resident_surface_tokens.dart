import 'package:flutter/material.dart';

/// Shared surface and text tokens for resident-facing screens.
extension ResidentSurfaceTokens on BuildContext {
  bool get isDarkUi => Theme.of(this).brightness == Brightness.dark;

  ColorScheme get residentScheme => Theme.of(this).colorScheme;

  Color get appInk => isDarkUi
      ? residentScheme.onSurface
      : const Color(0xFF1F2937);

  Color get appMuted => isDarkUi
      ? residentScheme.onSurfaceVariant
      : const Color(0xFF6B7280);

  Color softSurface({double darkAlpha = 0.74}) => isDarkUi
      ? residentScheme.surface.withValues(alpha: darkAlpha)
      : const Color(0xFFF8FAFC);

  Color residentOutline({double lightAlpha = 1}) => isDarkUi
      ? residentScheme.outlineVariant
      : const Color(0xFFE5E7EB).withValues(alpha: lightAlpha);

  Color glassFill({double lightAlpha = 0.84}) => isDarkUi
      ? residentScheme.surfaceContainerHighest.withValues(alpha: 0.88)
      : Colors.white.withValues(alpha: lightAlpha);

  Color glassBorder({double lightAlpha = 0.92}) => isDarkUi
      ? residentScheme.outlineVariant.withValues(alpha: 0.72)
      : Colors.white.withValues(alpha: lightAlpha);

  Color get avatarPlaceholder => isDarkUi
      ? residentScheme.primaryContainer
      : const Color(0xFFCFE5E9);

  Color get skeletonBar => isDarkUi
      ? residentScheme.surfaceContainerHighest
      : const Color(0xFFE5E7EB);

  Color get infoContainerBg => isDarkUi
      ? residentScheme.primaryContainer.withValues(alpha: 0.45)
      : const Color(0xFFEFF6FF);

  Color get infoContainerBorder => isDarkUi
      ? residentScheme.primary.withValues(alpha: 0.42)
      : const Color(0xFFBFDBFE);

  Color onAccent(Color accent) =>
      accent.computeLuminance() > 0.55 ? const Color(0xFF1F2937) : Colors.white;

  List<BoxShadow> softSurfaceShadow({
    double lightOpacity = 0.10,
    double darkOpacity = 0.24,
    double blurRadius = 24,
    double dy = 12,
  }) {
    return [
      BoxShadow(
        color: Colors.black.withValues(
          alpha: isDarkUi ? darkOpacity : lightOpacity,
        ),
        blurRadius: blurRadius,
        spreadRadius: -4,
        offset: Offset(0, dy),
      ),
    ];
  }

  InputDecoration residentInputDecoration({
    required String label,
    required String hint,
    double borderRadius = 16,
  }) {
    final scheme = residentScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: isDarkUi
          ? scheme.surfaceContainerHighest
          : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: residentOutline()),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: residentOutline()),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
      labelStyle: TextStyle(color: appMuted),
      hintStyle: TextStyle(color: appMuted.withValues(alpha: 0.72)),
    );
  }
}
