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
