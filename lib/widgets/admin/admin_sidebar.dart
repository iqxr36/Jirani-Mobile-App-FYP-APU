import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/core/constants/app_constants.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.activeKey,
    required this.onNavigate,
    required this.onLogout,
  });

  final String activeKey;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            _Item(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              selected: activeKey == 'dashboard',
              onTap: () => onNavigate('dashboard'),
            ),
            _Item(
              icon: Icons.verified_user_outlined,
              label: 'Verification Requests',
              selected: activeKey == 'verification',
              onTap: () => onNavigate('verification'),
            ),
            _Item(
              icon: Icons.people_outline,
              label: 'Users',
              selected: activeKey == 'users',
              onTap: () => onNavigate('users'),
            ),
            _Item(
              icon: Icons.flag_outlined,
              label: 'Reports',
              selected: activeKey == 'reports',
              onTap: () => onNavigate('reports'),
            ),
            _Item(
              icon: Icons.storefront_outlined,
              label: 'Listings',
              selected: activeKey == 'listings',
              onTap: () => onNavigate('listings'),
            ),
            _Item(
              icon: Icons.settings_outlined,
              label: 'Settings',
              selected: activeKey == 'settings',
              onTap: () => onNavigate('settings'),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      onTap: onTap,
    );
  }
}
