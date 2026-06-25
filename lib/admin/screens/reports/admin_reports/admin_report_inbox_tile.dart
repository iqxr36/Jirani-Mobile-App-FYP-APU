part of '../admin_reports_screen.dart';

class AdminReportInboxTile extends StatelessWidget {
  const AdminReportInboxTile({
    super.key,
    required this.report,
    required this.selected,
    required this.onTap,
  });

  final AdminReportRow report;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      onTap: onTap,
      minVerticalPadding: 14,
      leading: AdminPriorityDot(priority: report.priority),
      title: Text(
        report.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        report.inboxSubtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

