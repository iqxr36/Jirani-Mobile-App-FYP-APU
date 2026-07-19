// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : residency_tokens.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../residency_verification_view.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 390;
const int _kMaxDocumentBytes = 25 * 1024 * 1024;
const _kImageAndPdfDocumentExtensions = [
  'jpg',
  'jpeg',
  'png',
  'webp',
  'heic',
  'heif',
  'pdf',
];

Color _surface(BuildContext context) => context.isDarkUi
    ? context.residentScheme.surfaceContainerHighest.withValues(alpha: 0.88)
    : Colors.white;

Color _outline(BuildContext context, {double alpha = 0.16}) => context.isDarkUi
    ? context.residentScheme.outlineVariant
    : Colors.black.withValues(alpha: alpha);
