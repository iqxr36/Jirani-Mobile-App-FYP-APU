// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : notification_permission_view.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Wednesday,24-June-2026
// Last Edited on  : Saturday,18-July-2026

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/shared/data/repositories/verification_permission_repository.dart';
import 'package:jirani/resident/screens/camera/camera_permission_view.dart';
import 'package:permission_handler/permission_handler.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 390;

/// Notification permission — Figma: illustration, title, info card, allow / maybe later.
// Notification permission feature: asks the resident to enable push notifications during onboarding.
class NotificationPermissionView extends StatefulWidget {
  const NotificationPermissionView({super.key});

  @override
  State<NotificationPermissionView> createState() =>
      _NotificationPermissionViewState();
}

class _NotificationPermissionViewState
    extends State<NotificationPermissionView> {
  final _permissionRepository = VerificationPermissionRepository();
  bool _allowing = false;
  bool _skipping = false;

  bool get _buttonsLocked => _allowing || _skipping;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _completePermissionFlow() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const CameraPermissionView()),
    );
  }

  Future<void> _showNotificationSettingsDialog() async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notifications Are Disabled'),
        content: const Text(
          'Enable notifications in app settings to receive messages, lending updates, service bookings, and community alerts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (shouldOpen == true) await openAppSettings();
  }

  // Notification permission feature: stores notification permission state and FCM token preference.
  Future<void> _saveNotificationPreference({
    required bool enabled,
    required String status,
    String? token,
  }) async {
    await _permissionRepository.saveNotificationPreference(
      enabled: enabled,
      status: status,
      token: token,
    );
  }

  // Notification permission feature: requests OS notification permission and saves the result.
  Future<void> _handleAllowNotifications() async {
    if (_buttonsLocked) return;
    setState(() => _allowing = true);
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (!mounted) return;

      final status = settings.authorizationStatus;
      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        final token = await FirebaseMessaging.instance.getToken();
        final statusStr = status == AuthorizationStatus.provisional
            ? 'provisional'
            : 'authorized';
        await _saveNotificationPreference(
          enabled: true,
          status: statusStr,
          token: token,
        );
        if (!mounted) return;
        _completePermissionFlow();
      } else {
        await _saveNotificationPreference(
          enabled: false,
          status: 'denied',
          token: null,
        );
        if (!mounted) return;
        _showSnack(
          'Notifications remain disabled until you enable them in settings.',
        );
        await _showNotificationSettingsDialog();
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Could not update notification settings.');
        _completePermissionFlow();
      }
    } finally {
      if (mounted) setState(() => _allowing = false);
    }
  }

  // Notification permission feature: records skipped notification permission and continues onboarding.
  Future<void> _handleMaybeLater() async {
    if (_buttonsLocked) return;
    setState(() => _skipping = true);
    try {
      await _saveNotificationPreference(
        enabled: false,
        status: 'skipped',
        token: null,
      );
      if (!mounted) return;
      _completePermissionFlow();
    } catch (_) {
      if (mounted) {
        _showSnack('Could not save your preference.');
        _completePermissionFlow();
      }
    } finally {
      if (mounted) setState(() => _skipping = false);
    }
  }

  Widget _buildIllustration() {
    return SizedBox(
      height: 210,
      width: double.infinity,
      child: Image.asset(
        'assets/perm2.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildPlaceholderIllustration(context),
      ),
    );
  }

  Widget _buildPlaceholderIllustration(BuildContext context) {
    final softTeal = _kBrandTeal.withValues(alpha: 0.14);
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 20,
          top: 24,
          child: Icon(Icons.home_rounded, size: 26, color: softTeal),
        ),
        Positioned(
          right: 28,
          top: 32,
          child: Icon(Icons.person_outline_rounded, size: 24, color: softTeal),
        ),
        Positioned(
          left: 36,
          bottom: 32,
          child: Icon(Icons.shield_outlined, size: 22, color: softTeal),
        ),
        Positioned(
          right: 40,
          bottom: 28,
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            size: 22,
            color: softTeal,
          ),
        ),
        Container(
          width: 118,
          height: 168,
          decoration: BoxDecoration(
            color: context.glassFill(),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: softTeal, width: 2),
            boxShadow: [
              BoxShadow(
                color: _kBrandTeal.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_active_rounded,
                size: 48,
                color: _kBrandTeal,
              ),
              const SizedBox(height: 8),
              Container(
                width: 56,
                height: 6,
                decoration: BoxDecoration(
                  color: softTeal,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Stay connected with your community',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _kBrandTeal,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.glassFill(),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _kBrandTeal.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: _kBrandTeal,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Enable notifications to receive updates about nearby requests, lending activity, service bookings, and messages from trusted neighbors.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.appInk,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllowNotificationsButton() {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _kBrandTeal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kBrandTeal.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _buttonsLocked ? null : _handleAllowNotifications,
        child: _allowing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Enabling...',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              )
            : const Text(
                'Allow Notifications',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildMaybeLaterButton() {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF787880).withValues(alpha: 0.16),
          foregroundColor: _kBrandTeal,
          disabledForegroundColor: _kBrandTeal.withValues(alpha: 0.45),
          disabledBackgroundColor: const Color(
            0xFF787880,
          ).withValues(alpha: 0.10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _buttonsLocked ? null : _handleMaybeLater,
        child: const Text(
          'Maybe Later',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = JiraniResponsive.bottomInset(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 0, 28, 18 + bottomInset),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _kMaxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 28),
                        _buildIllustration(),
                        const SizedBox(height: 22),
                        _buildTitle(),
                        const SizedBox(height: 22),
                        _buildInfoCard(context),
                      ],
                    ),
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _kMaxContentWidth,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        _buildAllowNotificationsButton(),
                        const SizedBox(height: 8),
                        _buildMaybeLaterButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
