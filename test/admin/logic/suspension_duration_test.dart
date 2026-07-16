import 'package:flutter_test/flutter_test.dart';
import 'package:jirani/admin/logic/suspension_duration.dart';

void main() {
  group('SuspensionDuration', () {
    final startsAt = DateTime(2026, 7, 16, 10, 30);

    test('calculates each timed suspension from the selected start', () {
      expect(
        SuspensionDuration.oneDay.endsAt(startsAt),
        DateTime(2026, 7, 17, 10, 30),
      );
      expect(
        SuspensionDuration.sevenDays.endsAt(startsAt),
        DateTime(2026, 7, 23, 10, 30),
      );
      expect(
        SuspensionDuration.thirtyDays.endsAt(startsAt),
        DateTime(2026, 8, 15, 10, 30),
      );
    });

    test('indefinite suspension has no automatic end time', () {
      expect(SuspensionDuration.indefinite.endsAt(startsAt), isNull);
    });
  });
}
