// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : admin_reports_tokens.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

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
