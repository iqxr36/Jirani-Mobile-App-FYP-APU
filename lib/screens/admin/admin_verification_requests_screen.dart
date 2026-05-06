import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/providers/admin_provider.dart';
import 'package:fyp_flutter_application/providers/auth_provider.dart';
import 'package:fyp_flutter_application/screens/admin/admin_dashboard_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_listings_placeholder_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_reports_placeholder_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_settings_placeholder_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_unauthorized_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_users_placeholder_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_verification_request_details_screen.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_section_card.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_sidebar.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_status_chip.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_status_filter_bar.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_top_bar.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_verification_request_card.dart';
import 'package:provider/provider.dart';

class AdminVerificationRequestsScreen extends StatefulWidget {
  const AdminVerificationRequestsScreen({super.key});

  @override
  State<AdminVerificationRequestsScreen> createState() => _AdminVerificationRequestsScreenState();
}

class _AdminVerificationRequestsScreenState extends State<AdminVerificationRequestsScreen> {
  final _searchCtrl = TextEditingController();
  void _navigateByKey(String key) {
    if (key == 'verification') return;
    final routes = <String, Widget>{
      'dashboard': const AdminDashboardScreen(),
      'users': const AdminUsersPlaceholderScreen(),
      'reports': const AdminReportsPlaceholderScreen(),
      'listings': const AdminListingsPlaceholderScreen(),
      'settings': const AdminSettingsPlaceholderScreen(),
    };
    final target = routes[key];
    if (target == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => target));
  }
  void _openDetails(String requestId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminVerificationRequestDetailsScreen(requestId: requestId),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().watchVerificationRequests(status: 'submitted');
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final vm = context.watch<AdminProvider>();
    final user = auth.currentUser;
    if (user == null || !user.isAdmin) {
      return const AdminUnauthorizedScreen();
    }

    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = vm.verificationRequests.where((r) {
      if (q.isEmpty) return true;
      return r.fullName.toLowerCase().contains(q) ||
          r.email.toLowerCase().contains(q) ||
          r.communityName.toLowerCase().contains(q) ||
          r.unitNumber.toLowerCase().contains(q);
    }).toList(growable: false);
    final isWide = MediaQuery.of(context).size.width >= 900;

    final body = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminStatusFilterBar(
              selected: vm.selectedStatusFilter,
              onChanged: vm.setStatusFilter,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search name, email, community, unit',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (vm.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (vm.errorMessage != null) {
                    return Center(child: Text(vm.errorMessage!));
                  }
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No verification requests found.'));
                  }

                  if (!isWide) {
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final req = filtered[i];
                        return AdminVerificationRequestCard(
                          request: req,
                          onView: () => _openDetails(req.id),
                        );
                      },
                    );
                  }

                  return AdminSectionCard(
                    padding: const EdgeInsets.all(8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF181C1D)),
                        dataTextStyle: const TextStyle(color: Color(0xFF181C1D)),
                        columns: const [
                          DataColumn(label: Text('Resident')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Community')),
                          DataColumn(label: Text('Unit')),
                          DataColumn(label: Text('Document')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: filtered
                            .map(
                              (req) => DataRow(
                                onSelectChanged: (_) => _openDetails(req.id),
                                cells: [
                                  DataCell(Text(req.fullName)),
                                  DataCell(Text(req.email)),
                                  DataCell(Text(req.phoneNumber)),
                                  DataCell(Text(req.communityName)),
                                  DataCell(Text(req.unitNumber)),
                                  DataCell(Text(req.documentType)),
                                  DataCell(AdminStatusChip(status: req.status)),
                                  DataCell(
                                    FilledButton.tonalIcon(
                                      style: FilledButton.styleFrom(
                                        foregroundColor: const Color(0xFF00535B),
                                      ),
                                      onPressed: () => _openDetails(req.id),
                                      icon: const Icon(Icons.visibility_outlined),
                                      label: const Text('Review'),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );

    if (!isWide) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7FAFA),
        appBar: AppBar(title: const Text('Verification Requests')),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: Row(
        children: [
          AdminSidebar(activeKey: 'verification', onNavigate: _navigateByKey, onLogout: auth.logout),
          Expanded(
            child: Column(
              children: [
                AdminTopBar(
                  title: 'Verification Requests',
                  subtitle: 'Review resident identity submissions securely.',
                  trailing: CircleAvatar(
                    backgroundColor: const Color(0xFFACEFE7),
                    child: Text(user.email.isNotEmpty ? user.email[0].toUpperCase() : 'A'),
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
