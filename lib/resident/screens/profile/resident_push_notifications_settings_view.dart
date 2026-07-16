import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/shared/data/repositories/verification_permission_repository.dart';
import 'package:jirani/shared/logic/auth_viewmodel.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 420;

/// Resident settings feature: lets residents enable or disable push notifications.
class ResidentPushNotificationsSettingsView extends StatefulWidget {
  const ResidentPushNotificationsSettingsView({super.key});

  @override
  State<ResidentPushNotificationsSettingsView> createState() =>
      _ResidentPushNotificationsSettingsViewState();
}

class _ResidentPushNotificationsSettingsViewState
    extends State<ResidentPushNotificationsSettingsView> {
  final _permissionRepository = VerificationPermissionRepository();
  bool _enabled = true;
  bool _neighborUpdatesEnabled = true;
  bool _loading = true;
  bool _savingPush = false;
  bool _savingNeighbor = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();
      final data = snap.data();
      final value = data?['notificationEnabled'];
      final neighborValue = data?[AppConstants.userNeighborUpdatesEnabledField];
      if (!mounted) return;
      setState(() {
        if (value is bool) {
          _enabled = value;
        }
        if (neighborValue is bool) {
          _neighborUpdatesEnabled = neighborValue;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setEnabled(bool value) async {
    if (_savingPush) return;

    if (value && !kIsWeb) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!authorized) {
        if (!mounted) return;
        _showSnack(
          'Allow notifications in your device settings to receive alerts.',
        );
        await openAppSettings();
        return;
      }
    }

    if (value && kIsWeb) {
      _showSnack('Push notifications are not available on web.');
      return;
    }

    setState(() {
      _enabled = value;
      _savingPush = true;
    });

    try {
      if (value && !kIsWeb) {
        final token = await FirebaseMessaging.instance.getToken();
        final status = await FirebaseMessaging.instance.getNotificationSettings();
        final statusStr =
            status.authorizationStatus == AuthorizationStatus.provisional
            ? 'provisional'
            : 'authorized';
        await _permissionRepository.saveNotificationPreference(
          enabled: true,
          status: statusStr,
          token: token,
        );
      } else {
        await _permissionRepository.updateNotificationEnabled(enabled: false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _enabled = !value);
      _showSnack('Could not update notification settings.');
    } finally {
      if (mounted) setState(() => _savingPush = false);
    }
  }

  Future<void> _setNeighborUpdatesEnabled(bool value) async {
    if (_savingNeighbor) return;

    setState(() {
      _neighborUpdatesEnabled = value;
      _savingNeighbor = true;
    });

    try {
      await _permissionRepository.updateNeighborUpdatesEnabled(enabled: value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _neighborUpdatesEnabled = !value);
      _showSnack('Could not update neighbor activity settings.');
    } finally {
      if (mounted) setState(() => _savingNeighbor = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      'Choose whether Jirani can send alerts to this device',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _Panel(
                      child: _loading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 28),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _kBrandTeal,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                _ToggleRow(
                                  icon: Icons.notifications_outlined,
                                  label: 'Push Notifications',
                                  enabled: _enabled,
                                  saving: _savingPush,
                                  onChanged: _setEnabled,
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: scheme.outlineVariant,
                                ),
                                _ToggleRow(
                                  icon: Icons.groups_2_outlined,
                                  label: 'Neighbor activity updates',
                                  enabled: _neighborUpdatesEnabled,
                                  saving: _savingNeighbor,
                                  onChanged: _setNeighborUpdatesEnabled,
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: scheme.outlineVariant,
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    14,
                                    4,
                                    10,
                                  ),
                                  child: Text(
                                    _enabled
                                        ? 'You will receive updates about messages, bookings, community posts, and residence activity.'
                                        : 'You will not receive push alerts. You can still check activity inside the app.',
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 14),
                    _Panel(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What you may receive',
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _Bullet(
                              text: 'New chat messages and booking updates',
                              isDark: isDark,
                            ),
                            _Bullet(
                              text: 'Community announcements in your residence',
                              isDark: isDark,
                            ),
                            _Bullet(
                              text: 'Verification and account reminders',
                              isDark: isDark,
                            ),
                            _Bullet(
                              text:
                                  'New listings and services from connected neighbors',
                              isDark: isDark,
                            ),
                          ],
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
            'Push Notifications',
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

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

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
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: child,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.saving,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool saving;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
            color: scheme.onSurface,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (saving)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _kBrandTeal,
              ),
            )
          else
            Switch.adaptive(
              value: enabled,
              activeThumbColor: _kBrandTeal,
              activeTrackColor: _kBrandTeal.withValues(alpha: 0.24),
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _kBrandTeal.withValues(alpha: isDark ? 0.9 : 1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
