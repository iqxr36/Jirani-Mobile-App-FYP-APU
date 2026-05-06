import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/providers/auth_provider.dart';
import 'package:fyp_flutter_application/screens/admin/admin_dashboard_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_listings_placeholder_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_reports_placeholder_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_settings_placeholder_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_verification_requests_screen.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_section_card.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_sidebar.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_top_bar.dart';
import 'package:provider/provider.dart';

class AdminUsersPlaceholderScreen extends StatefulWidget {
  const AdminUsersPlaceholderScreen({super.key});

  @override
  State<AdminUsersPlaceholderScreen> createState() => _AdminUsersPlaceholderScreenState();
}

class _AdminUsersPlaceholderScreenState extends State<AdminUsersPlaceholderScreen> {
  void _navigateByKey(String key) {
    if (key == 'users') return;
    final routes = <String, Widget>{
      'dashboard': const AdminDashboardScreen(),
      'verification': const AdminVerificationRequestsScreen(),
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
    final isWide = MediaQuery.of(context).size.width >= 1000;
    final auth = context.read<AuthProvider>();
    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search residents by name, unit or block',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBEC8CA))),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: const [
            Chip(label: Text('All Residents')),
            Chip(label: Text('Verified')),
            Chip(label: Text('Pending')),
            Chip(label: Text('Rejected')),
          ],
        ),
        const SizedBox(height: 12),
        AdminSectionCard(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('Resident Name')),
                DataColumn(label: Text('Community Block')),
                DataColumn(label: Text('Unit Number')),
                DataColumn(label: Text('Verification Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: [
                DataRow(cells: [
                  DataCell(Text('No residents loaded')),
                  DataCell(Text('—')),
                  DataCell(Text('—')),
                  DataCell(Text('Pending')),
                  DataCell(Text('View Profile • Message • Revoke Access')),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            SizedBox(width: 240, child: AdminSectionCard(child: Text('Total Residents: 0'))),
            SizedBox(width: 240, child: AdminSectionCard(child: Text('Pending Verifications: 0'))),
            SizedBox(width: 240, child: AdminSectionCard(child: Text('Trust Score Avg.: N/A'))),
          ],
        ),
      ],
    );

    if (!isWide) {
      return Scaffold(
        appBar: AppBar(title: const Text('Users Management')),
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: Row(
        children: [
          AdminSidebar(activeKey: 'users', onNavigate: _navigateByKey, onLogout: auth.logout),
          Expanded(
            child: Column(
              children: [
                const AdminTopBar(
                  title: 'Users Management',
                  subtitle: 'Search and monitor resident verification posture.',
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
