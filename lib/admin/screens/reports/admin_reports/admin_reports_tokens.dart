part of '../admin_reports_screen.dart';

enum _ReportInboxFilter { open, completed }

AppUser? _residentById(List<AppUser> residents, String userId) {
  for (final resident in residents) {
    if (resident.uid == userId) return resident;
  }
  return null;
}
BoxDecoration _softCardDecoration(Color accent) {
  return BoxDecoration(
    color: AdminColors.background,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: accent.withValues(alpha: 0.16)),
  );
}
