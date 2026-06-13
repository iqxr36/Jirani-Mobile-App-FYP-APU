import 'package:flutter/material.dart';
import 'package:jirani/admin/models/admin_display_rows.dart';
import 'package:jirani/admin/theme/admin_colors.dart';
import 'package:jirani/admin/widgets/admin_layout_widgets.dart';
import 'package:jirani/admin/widgets/admin_status_widgets.dart';
import 'package:jirani/providers/admin_provider.dart';
import 'package:provider/provider.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<AdminProvider>().reports;
    final reportRows = reports.map(adminReportRowFromReport).toList();
    final selected = reportRows.isEmpty ? null : reportRows.first;
    return AdminPageScroll(
      children: [
        AdminControlBar(
          title: 'Reports and Complaints',
          subtitle:
              'Inbox-style triage for disputes, misuse, damaged items, and evidence.',
          controls: const [
            AdminFilterChipButton(label: 'Priority'),
            AdminFilterChipButton(label: 'Open'),
          ],
        ),
        const SizedBox(height: 20),
        if (selected == null)
          const AdminPanel(
            title: 'Report Inbox',
            child: AdminEmptyPanelMessage(
              icon: Icons.report_problem_rounded,
              title: 'No reports found',
              body: 'Resident complaints and report tickets will appear here.',
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final inbox = AdminPanel(
                title: 'Report Inbox',
                padding: EdgeInsets.zero,
                child: Column(
                  children: reportRows
                      .map((report) => AdminReportInboxTile(report: report))
                      .toList(),
                ),
              );
              final detail = AdminPanel(
                title: selected.title,
                action: selected.priority,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminReportDetailSection(
                      title: 'Reporter Details',
                      lines: [selected.reporter, selected.reporterEmail],
                    ),
                    AdminReportDetailSection(
                      title: 'Reported Content/User',
                      lines: [selected.target, selected.content],
                    ),
                    AdminReportDetailSection(
                      title: 'Reason & Evidence',
                      lines: [
                        selected.description,
                        'Evidence: 3 images attached',
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Dismiss Report'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () {},
                          icon: const Icon(Icons.campaign_rounded),
                          label: const Text('Issue Warning'),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AdminColors.accent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.block_rounded),
                          label: const Text('Suspend User'),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              if (wide) {
                return SizedBox(
                  height: 620,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 360, child: inbox),
                      const SizedBox(width: 20),
                      Expanded(child: detail),
                    ],
                  ),
                );
              }
              return Column(
                children: [inbox, const SizedBox(height: 20), detail],
              );
            },
          ),
      ],
    );
  }
}

class AdminReportInboxTile extends StatelessWidget {
  const AdminReportInboxTile({super.key, required this.report});

  final AdminReportRow report;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 14,
      leading: AdminPriorityDot(priority: report.priority),
      title: Text(
        report.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${report.reporter} - ${report.description}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class AdminReportDetailSection extends StatelessWidget {
  const AdminReportDetailSection({
    super.key,
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AdminColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: const TextStyle(color: AdminColors.ink),
              ),
            ),
        ],
      ),
    );
  }
}
