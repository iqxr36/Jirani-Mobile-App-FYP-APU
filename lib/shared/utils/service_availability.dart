import 'package:flutter/material.dart';
import 'package:jirani/shared/models/service_model.dart';

/// Machine-readable provider availability used for booking validation.
class ServiceAvailabilitySchedule {
  const ServiceAvailabilitySchedule({
    required this.weekdays,
    required this.startMinutes,
    required this.endMinutes,
    required this.displayLabel,
  });

  final Set<int> weekdays;
  final int startMinutes;
  final int endMinutes;
  final String displayLabel;

  bool get hasStructuredFields =>
      weekdays.isNotEmpty && endMinutes > startMinutes;

  bool isWeekdayAllowed(int weekday) => weekdays.contains(weekday);

  bool isTimeAllowed(int minutes) =>
      minutes >= startMinutes && minutes < endMinutes;

  bool matches({required int weekday, required int timeMinutes}) {
    return isWeekdayAllowed(weekday) && isTimeAllowed(timeMinutes);
  }

  String get validationMessage {
    if (displayLabel.trim().isNotEmpty) {
      return 'Provider is only available $displayLabel.';
    }
    return 'Selected date or time is outside provider availability.';
  }
}

const _weekdayLabels = <int, String>{
  DateTime.monday: 'Mon',
  DateTime.tuesday: 'Tue',
  DateTime.wednesday: 'Wed',
  DateTime.thursday: 'Thu',
  DateTime.friday: 'Fri',
  DateTime.saturday: 'Sat',
  DateTime.sunday: 'Sun',
};

int timeOfDayToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

int weekdayFromDate(DateTime date) => date.weekday;

ServiceAvailabilitySchedule parseServiceAvailability(ServiceModel service) {
  final structuredWeekdays = _parseWeekdayList(service.availableWeekdays);
  if (structuredWeekdays.isNotEmpty &&
      service.availabilityEndMinutes > service.availabilityStartMinutes) {
    return ServiceAvailabilitySchedule(
      weekdays: structuredWeekdays,
      startMinutes: service.availabilityStartMinutes,
      endMinutes: service.availabilityEndMinutes,
      displayLabel: service.availability.trim(),
    );
  }

  return _parseAvailabilityDisplayString(service.availability);
}

ServiceAvailabilitySchedule _parseAvailabilityDisplayString(String value) {
  final trimmed = value.trim();
  final lower = trimmed.toLowerCase();
  final weekdays = <int>{};

  if (lower.contains('everyday')) {
    weekdays.addAll(_weekdayLabels.keys);
  } else {
    if (lower.contains('mon-fri') || lower.contains('weekday')) {
      weekdays.addAll({
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      });
    }
    for (final entry in _weekdayLabels.entries) {
      if (lower.contains(entry.value.toLowerCase())) {
        weekdays.add(entry.key);
      }
    }
  }

  final timeMatch = RegExp(
    r'(\d{1,2}):(\d{2})\s*([ap]m)\s*-\s*(\d{1,2}):(\d{2})\s*([ap]m)',
    caseSensitive: false,
  ).firstMatch(trimmed);

  var startMinutes = 9 * 60;
  var endMinutes = 17 * 60;
  if (timeMatch != null) {
    final start = _parseClock(
      timeMatch.group(1),
      timeMatch.group(2),
      timeMatch.group(3),
    );
    final end = _parseClock(
      timeMatch.group(4),
      timeMatch.group(5),
      timeMatch.group(6),
    );
    if (start != null) startMinutes = start;
    if (end != null) endMinutes = end;
  }

  return ServiceAvailabilitySchedule(
    weekdays: weekdays,
    startMinutes: startMinutes,
    endMinutes: endMinutes,
    displayLabel: trimmed,
  );
}

Set<int> _parseWeekdayList(List<int> values) {
  return values.where((day) => day >= DateTime.monday && day <= DateTime.sunday).toSet();
}

int? _parseClock(String? hourText, String? minuteText, String? periodText) {
  final hour = int.tryParse(hourText ?? '');
  final minute = int.tryParse(minuteText ?? '');
  final period = periodText?.toLowerCase();
  if (hour == null || minute == null || period == null) return null;
  var resolvedHour = hour % 12;
  if (period == 'pm') resolvedHour += 12;
  return resolvedHour * 60 + minute;
}

int? minutesFromPreferredTimeLabel(String label) {
  final trimmed = label.trim();
  if (trimmed.isEmpty) return null;

  final twelveHour = RegExp(
    r'^(\d{1,2}):(\d{2})\s*([AP]M)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (twelveHour != null) {
    return _parseClock(
      twelveHour.group(1),
      twelveHour.group(2),
      twelveHour.group(3),
    );
  }

  final twentyFourHour = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(trimmed);
  if (twentyFourHour != null) {
    final hour = int.tryParse(twentyFourHour.group(1) ?? '');
    final minute = int.tryParse(twentyFourHour.group(2) ?? '');
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  return null;
}

void validateServiceAvailability({
  required ServiceAvailabilitySchedule schedule,
  required DateTime preferredDate,
  required String preferredTimeLabel,
}) {
  if (!schedule.hasStructuredFields && schedule.weekdays.isEmpty) {
    return;
  }

  final weekday = weekdayFromDate(preferredDate);
  final timeMinutes = minutesFromPreferredTimeLabel(preferredTimeLabel);
  if (timeMinutes == null) {
    throw Exception('Choose a valid preferred time.');
  }
  if (!schedule.matches(weekday: weekday, timeMinutes: timeMinutes)) {
    throw Exception(schedule.validationMessage);
  }
}

DateTime? nextAllowedBookingDate({
  required ServiceAvailabilitySchedule schedule,
  DateTime? after,
}) {
  if (schedule.weekdays.isEmpty) return null;
  final start = after ?? DateTime.now();
  for (var offset = 0; offset < 120; offset++) {
    final candidate = DateTime(
      start.year,
      start.month,
      start.day,
    ).add(Duration(days: offset));
    if (schedule.isWeekdayAllowed(candidate.weekday)) {
      return candidate;
    }
  }
  return null;
}

TimeOfDay clampPreferredTime({
  required ServiceAvailabilitySchedule schedule,
  required TimeOfDay preferred,
}) {
  final minutes = timeOfDayToMinutes(preferred);
  if (schedule.isTimeAllowed(minutes)) return preferred;
  final startHour = schedule.startMinutes ~/ 60;
  final startMinute = schedule.startMinutes % 60;
  return TimeOfDay(hour: startHour, minute: startMinute);
}

List<int> weekdaysToFirestoreList(Set<int> weekdays) {
  final sorted = weekdays.toList()..sort();
  return sorted;
}

Map<String, dynamic> availabilityFieldsForServiceWrite({
  required Set<int> weekdays,
  required TimeOfDay startTime,
  required TimeOfDay endTime,
}) {
  final startMinutes = timeOfDayToMinutes(startTime);
  final endMinutes = timeOfDayToMinutes(endTime);
  if (weekdays.isEmpty || endMinutes <= startMinutes) {
    throw Exception('Choose valid availability days and hours.');
  }
  return {
    'availableWeekdays': weekdaysToFirestoreList(weekdays),
    'availabilityStartMinutes': startMinutes,
    'availabilityEndMinutes': endMinutes,
  };
}
