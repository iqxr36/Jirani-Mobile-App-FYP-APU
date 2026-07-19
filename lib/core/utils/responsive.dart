// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : responsive.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Tuesday,16-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:math' as math;

import 'package:flutter/material.dart';

enum JiraniWindowClass { compact, medium, expanded }

enum JiraniContentWidth { auth, resident, admin, dialog }

class JiraniBreakpoints {
  const JiraniBreakpoints._();

  static const double compactMax = 599;
  static const double mediumMin = 600;
  static const double expandedMin = 1024;
  static const double adminWideMin = 900;
}

class JiraniResponsive {
  const JiraniResponsive._();

  static const Size referencePhoneSize = Size(390, 844);
  static const double minTouchTarget = 48;

  static JiraniWindowClass windowClassFor(double width) {
    if (width >= JiraniBreakpoints.expandedMin) {
      return JiraniWindowClass.expanded;
    }
    if (width >= JiraniBreakpoints.mediumMin) {
      return JiraniWindowClass.medium;
    }
    return JiraniWindowClass.compact;
  }

  static JiraniWindowClass windowClass(BuildContext context) {
    return windowClassFor(MediaQuery.sizeOf(context).width);
  }

  static bool isAdminWide(double width) =>
      width >= JiraniBreakpoints.adminWideMin;

  static double gutter(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 18;
    if (width < JiraniBreakpoints.mediumMin) return 24;
    if (width < JiraniBreakpoints.expandedMin) return 32;
    return 40;
  }

  static double maxWidth(JiraniContentWidth type) {
    switch (type) {
      case JiraniContentWidth.auth:
        return 390;
      case JiraniContentWidth.resident:
        return 390;
      case JiraniContentWidth.admin:
        return 1180;
      case JiraniContentWidth.dialog:
        return 560;
    }
  }

  static double averageScale(
    BuildContext context, {
    double min = 0.86,
    double max = 1.08,
  }) {
    final size = MediaQuery.sizeOf(context);
    final windowClass = windowClassFor(size.width);

    if (windowClass == JiraniWindowClass.expanded) {
      return 1;
    }

    final widthScale = size.width / referencePhoneSize.width;
    final heightScale = size.height / referencePhoneSize.height;
    final average = (widthScale * 0.56) + (heightScale * 0.44);
    final resolvedMax = windowClass == JiraniWindowClass.medium
        ? math.min(max, 1.04)
        : max;

    return average.clamp(min, resolvedMax);
  }

  static double scale(BuildContext context, double value) {
    return scaled(context, value);
  }

  static double scaled(BuildContext context, double value) {
    return value * averageScale(context);
  }

  static double scaledRadius(BuildContext context, double value) {
    return scaled(context, value);
  }

  static EdgeInsets scaledEdgeInsets(
    BuildContext context, {
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    final factor = averageScale(context);
    return EdgeInsets.fromLTRB(
      left * factor,
      top * factor,
      right * factor,
      bottom * factor,
    );
  }

  static double clamp(
    BuildContext context,
    double value, {
    double minFactor = 0.90,
    double maxFactor = 1.10,
  }) {
    final factor = averageScale(context, min: minFactor, max: maxFactor);
    return value * factor;
  }

  static double bottomInset(BuildContext context) {
    final media = MediaQuery.of(context);
    return math.max(media.padding.bottom, media.viewInsets.bottom);
  }

  static TextScaler clampedTextScaler(
    BuildContext context, {
    double min = 0.90,
    double max = 1.20,
  }) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return TextScaler.linear(scale.clamp(min, max));
  }

  static EdgeInsets pagePadding(
    BuildContext context, {
    double top = 24,
    double bottom = 24,
    bool includeKeyboard = false,
  }) {
    final horizontal = scaled(context, gutter(context));
    final scaledTop = scaled(context, top);
    final scaledBottom = scaled(context, bottom);
    final resolvedBottom = includeKeyboard
        ? math.max(scaledBottom, bottomInset(context))
        : scaledBottom + MediaQuery.paddingOf(context).bottom;
    return EdgeInsets.fromLTRB(
      horizontal,
      scaledTop,
      horizontal,
      resolvedBottom,
    );
  }
}

class JiraniResponsiveCenter extends StatelessWidget {
  const JiraniResponsiveCenter({
    super.key,
    required this.child,
    this.width = JiraniContentWidth.resident,
  });

  final Widget child;
  final JiraniContentWidth width;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: JiraniResponsive.maxWidth(width)),
        child: child,
      ),
    );
  }
}
