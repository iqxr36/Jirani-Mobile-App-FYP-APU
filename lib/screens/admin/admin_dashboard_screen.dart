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
import 'package:fyp_flutter_application/widgets/admin/admin_status_chip.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_top_bar.dart';
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
                    badgeLabel: 'ACTION REQUIRED',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: AdminStatCard(
                    title: 'Verified Residents',
                    count: stats['verifiedResidents'] ?? 0,
                    icon: Icons.verified_outlined,
                    badgeLabel: 'STABLE',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: AdminStatCard(
                    title: 'Active Listings',
                    count: stats['activeListings'] ?? 0,
                    icon: Icons.storefront_outlined,
                    tintColor: const Color(0xFFEBEEEE),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: AdminStatCard(
                    title: 'Safety Reports',
                    count: stats['safetyReports'] ?? 0,
                    icon: Icons.warning_amber_outlined,
                    badgeLabel: 'URGENT',
                    tintColor: const Color(0xFFFFDAD6),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        AdminSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent Verification Requests', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        const Text('Manage and review new resident identity submissions.'),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const AdminVerificationRequestsScreen()),
                      );
                    },
                    child: const Text('View All Requests'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (recent.isEmpty)
                const Text('No recent requests.')
              else
                ...recent.map(
                  (r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.fullName),
                    subtitle: Text('${r.email} • ${r.communityName} ${r.unitNumber}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AdminStatusChip(status: r.status),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AdminVerificationRequestsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.rate_review_outlined, size: 18),
                          label: const Text('Review'),
                        ),
                      ],
                    ),
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
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: isWide ? 520 : double.infinity,
              child: AdminSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Community Activity Feed', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 10),
                    ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.security_outlined), title: Text('Security Alert')),
                    ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.campaign_outlined), title: Text('Community announcement')),
                    ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.handyman_outlined), title: Text('Maintenance update')),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: isWide ? 380 : double.infinity,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF006D77),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trust Score Optimization', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('Focus urgent verification and safety trends to improve community trust.', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF00535B)),
                      onPressed: () {},
                      child: const Text('Action Safety Reports'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );

    if (!isWide) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7FAFA),
        appBar: AppBar(
          title: const Text('Dashboard Overview'),
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
      backgroundColor: const Color(0xFFF7FAFA),
      body: Row(
        children: [
          AdminSidebar(activeKey: 'dashboard', onNavigate: _navigateByKey, onLogout: auth.logout),
          Expanded(
            child: Column(
              children: [
                AdminTopBar(
                  title: 'Dashboard Overview',
                  subtitle: 'Securely monitor verification and trust operations.',
                  trailing: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFACEFE7),
                        child: Text(user.email.isNotEmpty ? user.email[0].toUpperCase() : 'A'),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.email, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Text('Community Admin', style: TextStyle(fontSize: 12, color: Color(0xFF3E494A))),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: content),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
