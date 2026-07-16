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
