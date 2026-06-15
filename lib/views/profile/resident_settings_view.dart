import 'package:flutter/material.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kMutedText = Color(0xFF8E8E93);
const double _kMaxContentWidth = 420;

class ResidentSettingsView extends StatelessWidget {
  const ResidentSettingsView({
    super.key,
    required this.darkTheme,
    required this.pushNotifications,
    required this.locationAlerts,
    required this.onDarkThemeChanged,
    required this.onPushNotificationsChanged,
    required this.onLocationAlertsChanged,
    required this.onPrivacy,
    required this.onLanguage,
    required this.onPaymentMethods,
    required this.onHelp,
  });

  final bool darkTheme;
  final bool pushNotifications;
  final bool locationAlerts;
  final ValueChanged<bool> onDarkThemeChanged;
  final ValueChanged<bool> onPushNotificationsChanged;
  final ValueChanged<bool> onLocationAlertsChanged;
  final VoidCallback onPrivacy;
  final VoidCallback onLanguage;
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
                      locationAlerts: locationAlerts,
                      onDarkThemeChanged: onDarkThemeChanged,
                      onPushNotificationsChanged: onPushNotificationsChanged,
                      onLocationAlertsChanged: onLocationAlertsChanged,
                      onPrivacy: onPrivacy,
                      onLanguage: onLanguage,
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
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.chevron_left_rounded, size: 32),
          color: _kBrandTeal,
          tooltip: 'Back',
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Notifications, theme, privacy and support',
                style: TextStyle(
                  color: _kMutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
    required this.locationAlerts,
    required this.onDarkThemeChanged,
    required this.onPushNotificationsChanged,
    required this.onLocationAlertsChanged,
    required this.onPrivacy,
    required this.onLanguage,
    required this.onPaymentMethods,
    required this.onHelp,
  });

  final bool darkTheme;
  final bool pushNotifications;
  final bool locationAlerts;
  final ValueChanged<bool> onDarkThemeChanged;
  final ValueChanged<bool> onPushNotificationsChanged;
  final ValueChanged<bool> onLocationAlertsChanged;
  final VoidCallback onPrivacy;
  final VoidCallback onLanguage;
  final VoidCallback onPaymentMethods;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.black.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
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
            icon: Icons.location_on_outlined,
            label: 'Location Alerts',
            value: locationAlerts,
            onChanged: onLocationAlertsChanged,
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
            icon: Icons.language_rounded,
            label: 'Language',
            trailing: 'English',
            onTap: onLanguage,
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
    this.trailing,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return _SettingsBaseRow(
      icon: icon,
      label: label,
      onTap: onTap,
      showDivider: showDivider,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                color: _kMutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, size: 24),
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
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Row(
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
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
            color: Colors.black.withValues(alpha: 0.10),
          ),
      ],
    );
  }
}
