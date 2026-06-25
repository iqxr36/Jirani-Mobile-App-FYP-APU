part of '../phone_verification_view.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 390;
const String _kFallbackDisplayPhone = '+60 12- 345 6789';

String _formatSeconds(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
