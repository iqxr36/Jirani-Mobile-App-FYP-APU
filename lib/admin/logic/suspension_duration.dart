// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : suspension_duration.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Thursday,16-July-2026
// Last Edited on  : Saturday,18-July-2026

enum SuspensionDuration {
  oneDay('1 day', Duration(days: 1)),
  threeDays('3 days', Duration(days: 3)),
  sevenDays('7 days', Duration(days: 7)),
  fourteenDays('14 days', Duration(days: 14)),
  thirtyDays('30 days', Duration(days: 30)),
  indefinite('Until manually reactivated', null);

  const SuspensionDuration(this.label, this.duration);

  final String label;
  final Duration? duration;

  DateTime? endsAt(DateTime startsAt) {
    final selectedDuration = duration;
    return selectedDuration == null ? null : startsAt.add(selectedDuration);
  }
}
