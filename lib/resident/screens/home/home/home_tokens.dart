part of '../resident_home_view.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 420;
const String _kHomeServicesAsset = 'assets/Home Services(1)-Photoroom.png';
const String _kShareItemsAsset = 'assets/Share Items-Photoroom.png';

List<BoxShadow> _softSurfaceShadow({
  double opacity = 0.10,
  double blurRadius = 24,
  double dy = 12,
}) {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: opacity),
      blurRadius: blurRadius,
      spreadRadius: -4,
      offset: Offset(0, dy),
    ),
  ];
}
