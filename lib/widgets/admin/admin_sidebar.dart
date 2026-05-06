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
      width: 262,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F4F4),
        border: Border(
          right: BorderSide(color: Color(0xFFBEC8CA), width: 0.8),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFACEFE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined, color: Color(0xFF00535B)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Admin Management',
                          style: TextStyle(fontSize: 12, color: Color(0xFF3E494A)),
                        ),
                      ],
                    ),
                  ),
                ],
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
              label: 'Verifications',
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
              icon: Icons.report_outlined,
              label: 'Reports',
              selected: activeKey == 'reports',
              onTap: () => onNavigate('reports'),
            ),
            _Item(
              icon: Icons.list_alt_outlined,
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
            _Item(
              icon: Icons.support_agent_outlined,
              label: 'Support',
              selected: false,
              onTap: () {},
            ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFACEFE7) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: selected ? const Color(0xFF00535B) : const Color(0xFF3E494A)),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF00535B) : const Color(0xFF3E494A),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        selected: selected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
