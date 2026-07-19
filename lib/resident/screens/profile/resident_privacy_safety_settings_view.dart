// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : resident_privacy_safety_settings_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,11-July-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:flutter/material.dart';
import 'package:jirani/resident/screens/profile/resident_edit_profile_view.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 420;

/// Resident settings feature: explains privacy controls and community safety options.
class ResidentPrivacySafetySettingsView extends StatelessWidget {
  const ResidentPrivacySafetySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;
    final user = context.watch<AuthViewModel>().currentUser;

    return JiraniBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 18, 16, 24 + bottom),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(onBack: () => Navigator.of(context).pop()),
                    const SizedBox(height: 4),
                    Text(
                      'How your information is used and kept safe',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionPanel(
                      icon: Icons.visibility_outlined,
                      title: 'Profile visibility',
                      body:
                          'Your public profile shows your name, photo, and community trust score to verified neighbors in your residence. Contact details such as email and phone are not shown to other residents.',
                    ),
                    const SizedBox(height: 12),
                    _SectionPanel(
                      icon: Icons.location_on_outlined,
                      title: 'Location & residence',
                      body:
                          'Jirani uses your residence assignment and geofence to show community content relevant to where you live. Location is not shared with other residents as a live map.',
                    ),
                    const SizedBox(height: 12),
                    _SectionPanel(
                      icon: Icons.shield_outlined,
                      title: 'Account safety',
                      body: user == null
                          ? 'Sign in to review verification status and keep your account secure.'
                          : user.isVerifiedResident
                          ? 'Your residency is verified. Keep your email and phone up to date so you can recover your account and receive important alerts.'
                          : 'Complete residency verification to unlock marketplace, services, and community features. Verification helps keep the community safe.',
                    ),
                    const SizedBox(height: 12),
                    _SectionPanel(
                      icon: Icons.report_gmailerrorred_outlined,
                      title: 'Community safety',
                      body:
                          'Report suspicious listings, messages, or behavior through the relevant screen in the app. Admins review reports and can remove content or restrict accounts that break community rules.',
                    ),
                    const SizedBox(height: 12),
                    _SectionPanel(
                      icon: Icons.storage_outlined,
                      title: 'Your data',
                      body:
                          'We store profile details, verification documents, messages, and activity needed to run marketplace and community features. You can update personal details anytime from your profile.',
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: user == null
                          ? null
                          : () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const ResidentEditProfileView(),
                                ),
                              );
                            },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit profile details'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kBrandTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left_rounded, size: 32),
              color: _kBrandTeal,
              tooltip: 'Back',
            ),
          ),
          const Text(
            'Privacy & Safety',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kBrandTeal,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.90)
            : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isDark
              ? scheme.outlineVariant.withValues(alpha: 0.72)
              : Colors.black.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.10),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: _kBrandTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
