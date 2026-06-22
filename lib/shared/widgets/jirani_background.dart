import 'package:flutter/material.dart';

/// Soft app background recreated from the Figma screen treatment.
class JiraniBackground extends StatelessWidget {
  const JiraniBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _JiraniBackgroundPainter(isDark: isDark)),
        child,
      ],
    );
  }
}

class _JiraniBackgroundPainter extends CustomPainter {
  const _JiraniBackgroundPainter({required this.isDark});

  final bool isDark;

  static const _teal = Color(0xFF006D77);
  static const _yellow = Color(0xFFFFCC00);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = isDark ? const Color(0xFF071113) : Colors.white,
    );

    final stroke = size.shortestSide * 0.42;
    final blur = size.shortestSide * 0.16;

    final tealPath = Path()
      ..moveTo(size.width * 0.70, size.height * 0.18)
      ..cubicTo(
        size.width * 0.47,
        size.height * 0.28,
        size.width * 0.86,
        size.height * 0.50,
        size.width * 0.58,
        size.height * 0.64,
      );
    canvas.drawPath(
      tealPath,
      Paint()
        ..color = _teal.withValues(alpha: isDark ? 0.34 : 0.74)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );

    final yellowPath = Path()
      ..moveTo(size.width * 0.10, size.height * 0.54)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.50,
        size.width * 0.32,
        size.height * 0.70,
        size.width * 0.58,
        size.height * 0.75,
      );
    canvas.drawPath(
      yellowPath,
      Paint()
        ..color = _yellow.withValues(alpha: isDark ? 0.16 : 0.58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.9
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = (isDark ? const Color(0xFF071113) : Colors.white)
            .withValues(alpha: isDark ? 0.34 : 0.26),
    );
  }

  @override
  bool shouldRepaint(covariant _JiraniBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
