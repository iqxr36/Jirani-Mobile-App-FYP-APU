// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_login_widgets.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,11-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/theme/admin_theme_preset.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/widgets/jirani_logo.dart';

const double _kFieldRadius = 12;
const double _kCardRadius = 20;
const double _kHeroLogoHeight = 148;

/// Full-bleed gradient backdrop with soft accent orbs.
class AdminLoginBackground extends StatelessWidget {
  const AdminLoginBackground({
    super.key,
    required this.primary,
    required this.secondary,
    required this.child,
  });

  final Color primary;
  final Color secondary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(primary, const Color(0xFF004E56), 0.35)!,
            primary,
            Color.lerp(secondary, Colors.white, 0.12)!,
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowOrb(
              diameter: 340,
              color: secondary.withValues(alpha: 0.45),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _GlowOrb(
              diameter: 280,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.35,
            left: MediaQuery.sizeOf(context).width * 0.18,
            child: _GlowOrb(
              diameter: 180,
              color: primary.withValues(alpha: 0.35),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: diameter * 0.45,
              spreadRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

/// Left brand panel shown on wide admin layouts.
class AdminLoginHeroPanel extends StatelessWidget {
  const AdminLoginHeroPanel({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: _HeroPanelPattern()),
        Positioned(
          top: 72,
          right: -28,
          child: _HeroAccentRing(
            diameter: 220,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -40,
          child: _HeroAccentRing(
            diameter: 160,
            color: secondary.withValues(alpha: 0.22),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(48, 40, 28, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _HeroLogoShowcase(),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Admin Portal',
                              style: textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Your community command center',
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Manage verification, residents, reports, and listings from one secure workspace built for neighborhood administrators.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _HeroTrustPill(
                            icon: Icons.verified_outlined,
                            label: 'Verified access',
                          ),
                          _HeroTrustPill(
                            icon: Icons.groups_2_outlined,
                            label: 'Community-first',
                          ),
                          _HeroTrustPill(
                            icon: Icons.history_edu_outlined,
                            label: 'Audit trail',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(18, 18, 18, 10),
                      child: Column(
                        children: [
                          _AdminLoginFeatureRow(
                            icon: Icons.verified_user_outlined,
                            title: 'Resident verification',
                            subtitle:
                                'Review documents and approve access quickly.',
                          ),
                          SizedBox(height: 14),
                          _AdminLoginFeatureRow(
                            icon: Icons.insights_outlined,
                            title: 'Live community insights',
                            subtitle:
                                'Track reports, listings, and activity at a glance.',
                          ),
                          SizedBox(height: 14),
                          _AdminLoginFeatureRow(
                            icon: Icons.shield_outlined,
                            title: 'Secure by design',
                            subtitle:
                                'Admin actions are logged and access is role-based.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 17,
                      color: secondary.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Authorized community administrators only.',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroLogoShowcase extends StatelessWidget {
  const _HeroLogoShowcase();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 325),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const JiraniLogo(height: _kHeroLogoHeight),
      ),
    );
  }
}

class _HeroAccentRing extends StatelessWidget {
  const _HeroAccentRing({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
      ),
    );
  }
}

class _HeroTrustPill extends StatelessWidget {
  const _HeroTrustPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.92)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanelPattern extends StatelessWidget {
  const _HeroPanelPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _HeroPanelPatternPainter());
  }
}

class _HeroPanelPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const spacing = 28.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    for (var x = spacing; x < size.width; x += spacing * 2) {
      for (var y = spacing; y < size.height; y += spacing * 2) {
        canvas.drawCircle(Offset(x, y), 1.6, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AdminLoginFeatureRow extends StatelessWidget {
  const _AdminLoginFeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Frosted login card wrapping the credential form.
class AdminLoginFormCard extends StatelessWidget {
  const AdminLoginFormCard({
    super.key,
    required this.primary,
    required this.child,
    this.compactHeader = false,
  });

  final Color primary;
  final Widget child;
  final bool compactHeader;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(_kCardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(_kCardRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.22),
                blurRadius: 48,
                offset: const Offset(0, 24),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compactHeader ? 24 : 32,
              compactHeader ? 24 : 36,
              compactHeader ? 24 : 32,
              compactHeader ? 24 : 32,
            ),
            child: child,
          ),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: card,
    );
  }
}

class AdminLoginCardHeader extends StatelessWidget {
  const AdminLoginCardHeader({
    super.key,
    required this.primary,
    this.showBrandMark = true,
  });

  final Color primary;
  final bool showBrandMark;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        if (showBrandMark) ...[
          const JiraniLogo(height: 88),
          const SizedBox(height: 20),
        ],
        Text(
          'Welcome back',
          style: textTheme.headlineSmall?.copyWith(
            color: AdminColors.ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to manage ${AppConstants.appName}',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AdminColors.muted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class AdminLoginErrorBanner extends StatelessWidget {
  const AdminLoginErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.danger.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AdminColors.danger,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AdminColors.ink,
                height: 1.4,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminLoginFooterNote extends StatelessWidget {
  const AdminLoginFooterNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: AdminColors.border, height: 1),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_iphone_outlined,
              size: 16,
              color: AdminColors.muted.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Residents should sign in through the mobile app.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AdminColors.muted,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shared input decoration for the admin login form.
InputDecoration adminLoginInputDecoration({
  required String label,
  required IconData prefixIcon,
  Widget? suffixIcon,
  Color? primary,
}) {
  final accent = primary ?? AdminThemePreset.teal.primary;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_kFieldRadius),
    borderSide: const BorderSide(color: AdminColors.border),
  );

  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(prefixIcon, size: 22),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kFieldRadius),
      borderSide: BorderSide(color: accent, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kFieldRadius),
      borderSide: BorderSide(color: AdminColors.danger.withValues(alpha: 0.7)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kFieldRadius),
      borderSide: const BorderSide(color: AdminColors.danger, width: 1.4),
    ),
  );
}
