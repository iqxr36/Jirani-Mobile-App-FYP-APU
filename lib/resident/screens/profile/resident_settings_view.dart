import 'package:flutter/material.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const double _kMaxContentWidth = 420;

// Resident settings feature: presents theme, notification, payment, privacy, and support settings.
class ResidentSettingsView extends StatelessWidget {
  const ResidentSettingsView({
    super.key,
    required this.darkTheme,
    required this.pushNotifications,
    required this.onDarkThemeChanged,
    required this.onPushNotificationsChanged,
    required this.onPrivacy,
    required this.onPaymentMethods,
    required this.onHelp,
  });

  final bool darkTheme;
  final bool pushNotifications;
  final ValueChanged<bool> onDarkThemeChanged;
  final ValueChanged<bool> onPushNotificationsChanged;
  final VoidCallback onPrivacy;
  final VoidCallback onPaymentMethods;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

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
                    _SettingsHeader(onBack: () => Navigator.of(context).pop()),
                    const SizedBox(height: 18),
                    _SettingsCard(
                      darkTheme: darkTheme,
                      pushNotifications: pushNotifications,
                      onDarkThemeChanged: onDarkThemeChanged,
                      onPushNotificationsChanged: onPushNotificationsChanged,
                      onPrivacy: onPrivacy,
                      onPaymentMethods: onPaymentMethods,
                      onHelp: onHelp,
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

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
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
                'Settings',
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
        ),
        const SizedBox(height: 4),
        Text(
          'Notifications, theme, privacy and support',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.darkTheme,
    required this.pushNotifications,
    required this.onDarkThemeChanged,
    required this.onPushNotificationsChanged,
    required this.onPrivacy,
    required this.onPaymentMethods,
    required this.onHelp,
  });

  final bool darkTheme;
  final bool pushNotifications;
  final ValueChanged<bool> onDarkThemeChanged;
  final ValueChanged<bool> onPushNotificationsChanged;
  final VoidCallback onPrivacy;
  final VoidCallback onPaymentMethods;
  final VoidCallback onHelp;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SettingsSwitchRow(
            icon: Icons.notifications_outlined,
            label: 'Push Notifications',
            value: pushNotifications,
            onChanged: onPushNotificationsChanged,
          ),
          _SettingsSwitchRow(
            icon: Icons.dark_mode_outlined,
            label: 'Dark Theme',
            value: darkTheme,
            onChanged: onDarkThemeChanged,
          ),
          _SettingsActionRow(
            icon: Icons.lock_outline_rounded,
            label: 'Privacy & Safety',
            onTap: onPrivacy,
          ),
          _SettingsActionRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Payment Methods',
            onTap: onPaymentMethods,
          ),
          _SettingsActionRow(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: onHelp,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsBaseRow(
      icon: icon,
      label: label,
      trailing: Switch.adaptive(
        value: value,
        activeThumbColor: _kBrandTeal,
        activeTrackColor: _kBrandTeal.withValues(alpha: 0.24),
        onChanged: onChanged,
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _SettingsBaseRow(
      icon: icon,
      label: label,
      onTap: onTap,
      showDivider: showDivider,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chevron_right_rounded,
            size: 24,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _SettingsBaseRow extends StatelessWidget {
  const _SettingsBaseRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Row(
        children: [
          Icon(icon, size: 21, color: scheme.onSurface),
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
          trailing,
        ],
      ),
    );

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: row,
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant,
          ),
      ],
    );
  }
}
