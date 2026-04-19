import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/reminders/presentation/utils/reminder_time_utils.dart';

void main() {
  group('rollReminderTimeToFuture', () {
    test('keeps selected time when already in the future', () {
      final now = DateTime(2026, 4, 15, 21, 00);
      final selected = DateTime(2026, 4, 15, 21, 15);

      final result = rollReminderTimeToFuture(selected, now: now);

      expect(result, selected);
    });

    test('rolls selected time to next day when in the past', () {
      final now = DateTime(2026, 4, 15, 21, 00);
      final selected = DateTime(2026, 4, 15, 20, 45);

      final result = rollReminderTimeToFuture(selected, now: now);

      expect(result, DateTime(2026, 4, 16, 20, 45));
    });
  });

  group('formatReminderOffsetLabel', () {
    test('formats days, hours, and minutes', () {
      final label = formatReminderOffsetLabel(
        const Duration(days: 1, hours: 2, minutes: 3),
      );

      expect(label, '1 day, 2 hours, 3 minutes');
    });

    test('never returns zero minutes', () {
      final label = formatReminderOffsetLabel(Duration.zero);

      expect(label, '1 minute');
    });
  });
}
