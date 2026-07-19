// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : verification_process_tokens.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../verification_process_view.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 390;

Color _surface(BuildContext context) => context.isDarkUi
    ? context.residentScheme.surfaceContainerHighest.withValues(alpha: 0.88)
    : Colors.white;

Color _outline(BuildContext context) => context.isDarkUi
    ? context.residentScheme.outlineVariant
    : Colors.black.withValues(alpha: 0.20);
