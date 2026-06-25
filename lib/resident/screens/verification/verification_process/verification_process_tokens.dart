part of '../verification_process_view.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 390;

Color _surface(BuildContext context) => context.isDarkUi
    ? context.residentScheme.surfaceContainerHighest.withValues(alpha: 0.88)
    : Colors.white;

Color _outline(BuildContext context) => context.isDarkUi
    ? context.residentScheme.outlineVariant
    : Colors.black.withValues(alpha: 0.20);
