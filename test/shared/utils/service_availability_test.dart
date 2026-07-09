import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/shared/models/service_model.dart';
import 'package:jirani/shared/utils/service_availability.dart';

ServiceModel _weekendService() {
  return ServiceModel(
    id: 'weekend-service',
    providerId: 'provider-1',
    providerName: 'Weekend Provider',
    providerEmail: 'provider@example.com',
    title: 'Weekend cleaning',
    description: 'Weekends only',
    category: 'homeCleaningUpkeep',
    priceType: 'fixed',
    priceAmount: 50,
    pricingMode: 'fixedJob',
    fixedJobPrice: 50,
    availability: 'Sat, Sun, 9:00 AM - 5:00 PM',
    availableWeekdays: const [DateTime.saturday, DateTime.sunday],
    availabilityStartMinutes: 9 * 60,
    availabilityEndMinutes: 17 * 60,
    status: 'active',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  test('parseServiceAvailability prefers structured service fields', () {
    final schedule = parseServiceAvailability(_weekendService());
    expect(schedule.weekdays, {DateTime.saturday, DateTime.sunday});
    expect(schedule.startMinutes, 9 * 60);
    expect(schedule.endMinutes, 17 * 60);
  });

  test('validateServiceAvailability rejects Monday for weekend-only service', () {
    final schedule = parseServiceAvailability(_weekendService());
    expect(
      () => validateServiceAvailability(
        schedule: schedule,
        preferredDate: DateTime(2026, 7, 6),
        preferredTimeLabel: '10:00 AM',
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Provider is only available'),
        ),
      ),
    );
  });

  test('validateServiceAvailability accepts Saturday within window', () {
    final schedule = parseServiceAvailability(_weekendService());
    expect(
      () => validateServiceAvailability(
        schedule: schedule,
        preferredDate: DateTime(2026, 7, 4),
        preferredTimeLabel: '10:00 AM',
      ),
      returnsNormally,
    );
  });

  test('validateServiceAvailability rejects time outside window', () {
    final schedule = parseServiceAvailability(_weekendService());
    expect(
      () => validateServiceAvailability(
        schedule: schedule,
        preferredDate: DateTime(2026, 7, 4),
        preferredTimeLabel: '8:00 PM',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('legacy availability string parses weekend hours', () {
    final service = ServiceModel(
      id: 'legacy',
      providerId: 'provider-1',
      providerName: 'Legacy Provider',
      providerEmail: 'provider@example.com',
      title: 'Legacy',
      description: 'Legacy',
      category: 'homeCleaningUpkeep',
      priceType: 'fixed',
      priceAmount: 50,
      availability: 'Sat, Sun, 9:00 AM - 5:00 PM',
      status: 'active',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    final schedule = parseServiceAvailability(service);
    expect(schedule.weekdays, {DateTime.saturday, DateTime.sunday});
    expect(schedule.isTimeAllowed(10 * 60), isTrue);
    expect(schedule.isTimeAllowed(20 * 60), isFalse);
  });

  test('availabilityFieldsForServiceWrite returns firestore fields', () {
    final fields = availabilityFieldsForServiceWrite(
      weekdays: {DateTime.saturday, DateTime.sunday},
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 17, minute: 0),
    );
    expect(fields['availableWeekdays'], [6, 7]);
    expect(fields['availabilityStartMinutes'], 540);
    expect(fields['availabilityEndMinutes'], 1020);
  });
}
