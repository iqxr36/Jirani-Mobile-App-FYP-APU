import 'package:flutter/material.dart';
import 'package:jirani/admin/logic/theme/admin_colors.dart';
import 'package:jirani/admin/logic/utils/admin_formatters.dart';
import 'package:jirani/admin/logic/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/logic/widgets/admin_status_widgets.dart';
import 'package:jirani/admin/providers/admin_provider.dart';
import 'package:provider/provider.dart';

class AdminResidentsScreen extends StatelessWidget {
  const AdminResidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final residents = admin.residents;
    return AdminPageScroll(
      children: [
        AdminControlBar(
          title: 'Resident Directory',
          subtitle:
              'Search, filter, and monitor account health across communities.',
          controls: const [
            AdminFilterChipButton(label: 'Status'),
            AdminFilterChipButton(label: 'Community'),
            AdminTonalActionButton(
              icon: Icons.download_rounded,
              label: 'Export Data',
            ),
          ],
        ),
        const SizedBox(height: 20),
        AdminPanel(
          title: 'All Residents',
          action: '${residents.length} accounts',
          padding: EdgeInsets.zero,
          child: residents.isEmpty
              ? const AdminEmptyPanelMessage(
                  icon: Icons.groups_2_rounded,
                  title: 'No residents found',
                  body:
                      'Residents in this admin community will appear after registration.',
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                      color: AdminColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                    columns: const [
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Community')),
                      DataColumn(label: Text('Verification')),
                      DataColumn(label: Text('Account')),
                      DataColumn(label: Text('')),
                    ],
                    rows: residents
                        .map(
                          (resident) => DataRow(
                            cells: [
                              DataCell(
                                AdminIdentityCell(name: resident.fullName),
                              ),
                              DataCell(Text(resident.email)),
                              DataCell(Text(resident.communityName)),
                              DataCell(
                                AdminStatusPill(
                                  label: adminStatusLabel(
                                    resident.verificationStatus,
                                  ),
                                  color: resident.isVerifiedResident
                                      ? AdminColors.success
                                      : AdminColors.warning,
                                ),
                              ),
                              const DataCell(
                                AdminStatusPill(
                                  label: 'Active',
                                  color: AdminColors.primary,
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  tooltip: 'More options',
                                  onPressed: () {},
                                  icon: const Icon(Icons.more_horiz_rounded),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }
}
