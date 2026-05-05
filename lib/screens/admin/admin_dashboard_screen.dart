import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/providers/admin_provider.dart';
import 'package:fyp_flutter_application/providers/auth_provider.dart';
import 'package:fyp_flutter_application/screens/admin/admin_listings_placeholder_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_reports_placeholder_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_settings_placeholder_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_unauthorized_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_users_placeholder_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_verification_requests_screen.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_section_card.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_sidebar.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_stat_card.dart';
import 'package:provider/provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AdminProvider>();
      vm.loadDashboardStats();
      vm.watchVerificationRequests(status: 'submitted');
    });
  }

  void _navigateByKey(String key) {
    if (key == 'dashboard') return;
    final routes = <String, Widget>{
      'verification': const AdminVerificationRequestsScreen(),
      'users': const AdminUsersPlaceholderScreen(),
      'reports': const AdminReportsPlaceholderScreen(),
      'listings': const AdminListingsPlaceholderScreen(),
      'settings': const AdminSettingsPlaceholderScreen(),
    };
    final target = routes[key];
    if (target == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => target));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final adminVm = context.watch<AdminProvider>();
    final user = auth.currentUser;
    if (user == null || !user.isAdmin) {
      return const AdminUnauthorizedScreen();
    }

    final isWide = MediaQuery.of(context).size.width >= 1000;
    final stats = adminVm.dashboardStats;
    final recent = adminVm.verificationRequests.take(5).toList(growable: false);

    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Dashboard', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  const Text('Manage resident verification and community safety.'),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(user.email),
                const SizedBox(height: 4),
                const Chip(label: Text('Community Admin')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = isWide ? (constraints.maxWidth - 24) / 4 : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: AdminStatCard(
                    title: 'Submitted Requests',
                    count: stats['submittedRequests'] ?? 0,
                    icon: Icons.pending_actions_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: AdminStatCard(
                    title: 'Verified Residents',
                    count: stats['verifiedResidents'] ?? 0,
                    icon: Icons.verified_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: AdminStatCard(
                    title: 'Rejected Requests',
                    count: stats['rejectedRequests'] ?? 0,
                    icon: Icons.cancel_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: AdminStatCard(
                    title: 'Total Users',
                    count: stats['totalUsers'] ?? 0,
                    icon: Icons.people_alt_outlined,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        AdminSectionCard(
          child: Row(
            children: [
              const Expanded(
                child: Text('Review Verification Requests'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AdminVerificationRequestsScreen()),
                  );
                },
                child: const Text('Open'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recent Submitted Requests', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (recent.isEmpty)
                const Text('No recent requests.')
              else
                ...recent.map(
                  (r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.fullName),
                    subtitle: Text('${r.email} • ${r.communityName} ${r.unitNumber}'),
                    trailing: Chip(label: Text(r.status)),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const AdminVerificationRequestsScreen()),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    if (!isWide) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              onPressed: auth.logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        drawer: Drawer(
          child: AdminSidebar(activeKey: 'dashboard', onNavigate: _navigateByKey, onLogout: auth.logout),
        ),
        body: content,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(activeKey: 'dashboard', onNavigate: _navigateByKey, onLogout: auth.logout),
          Expanded(child: content),
        ],
      ),
    );
  }
}
