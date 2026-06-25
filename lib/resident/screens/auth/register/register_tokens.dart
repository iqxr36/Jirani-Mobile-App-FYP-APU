part of '../register_view.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kCardRadius = 26;
const double _kFieldRadius = 10;

TextStyle _registerLabelStyle(BuildContext context) => TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: context.appInk,
);

InputDecoration _registerInputDecoration(
  BuildContext context, {
  required String hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: context.isDarkUi
        ? context.residentScheme.surfaceContainerHighest
        : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    hintStyle: TextStyle(
      color: context.appMuted.withValues(alpha: 0.72),
      fontSize: 14,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kFieldRadius),
      borderSide: BorderSide(color: context.residentOutline(lightAlpha: 0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kFieldRadius),
      borderSide: const BorderSide(color: _kBrandTeal, width: 1.3),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kFieldRadius),
      borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.8)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kFieldRadius),
      borderSide: const BorderSide(color: Colors.red, width: 1.3),
    ),
  );
}
