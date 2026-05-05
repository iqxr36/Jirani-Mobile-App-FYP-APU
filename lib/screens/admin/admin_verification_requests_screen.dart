import 'package:flutter/material.dart';
import 'package:fyp_flutter_application/providers/admin_provider.dart';
import 'package:fyp_flutter_application/providers/auth_provider.dart';
import 'package:fyp_flutter_application/screens/admin/admin_unauthorized_screen.dart';
import 'package:fyp_flutter_application/screens/admin/admin_verification_request_details_screen.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_status_filter_bar.dart';
import 'package:fyp_flutter_application/widgets/admin/admin_verification_request_card.dart';
import 'package:provider/provider.dart';

class AdminVerificationRequestsScreen extends StatefulWidget {
  const AdminVerificationRequestsScreen({super.key});

  @override
  State<AdminVerificationRequestsScreen> createState() => _AdminVerificationRequestsScreenState();
}

class _AdminVerificationRequestsScreenState extends State<AdminVerificationRequestsScreen> {
  final _searchCtrl = TextEditingController();

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

    return Scaffold(
      appBar: AppBar(title: const Text('Verification Requests')),
      body: Padding(
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
                          onView: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => AdminVerificationRequestDetailsScreen(requestId: req.id),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }

                  return SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Resident')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Community')),
                        DataColumn(label: Text('Unit')),
                        DataColumn(label: Text('Document')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Submitted')),
                        DataColumn(label: Text('Action')),
                      ],
                      rows: filtered
                          .map(
                            (req) => DataRow(
                              cells: [
                                DataCell(Text(req.fullName)),
                                DataCell(Text(req.email)),
                                DataCell(Text(req.phoneNumber)),
                                DataCell(Text(req.communityName)),
                                DataCell(Text(req.unitNumber)),
                                DataCell(Text(req.documentType)),
                                DataCell(Chip(label: Text(req.status))),
                                DataCell(Text(_fmt(req.submittedAt))),
                                DataCell(
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => AdminVerificationRequestDetailsScreen(requestId: req.id),
                                        ),
                                      );
                                    },
                                    child: const Text('View'),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(growable: false),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
