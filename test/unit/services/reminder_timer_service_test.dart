import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/features/reminders/models/reminder.dart';
import 'package:nexus/features/reminders/models/reminder_repository.dart';
import 'package:nexus/features/reminders/services/reminder_timer_service.dart';

import '../../helpers/fake_notification_service.dart';

void main() {
  late ReminderRepository repo;
  late FakeNotificationService notifications;
  late ReminderTimerService timerService;

  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.reminder)) {
      Hive.registerAdapter(ReminderAdapter());
    }
    await Hive.openBox<Reminder>(HiveBoxes.reminders);
    repo = ReminderRepository();
    notifications = FakeNotificationService();
    timerService = ReminderTimerService(
      repo: repo,
      notifications: notifications,
    );
  });

  tearDown(() async {
    timerService.dispose();
    await tearDownTestHive();
  });

  group('ReminderTimerService', () {
    test('fires immediately for very recently past reminder', () async {
      final justNow = DateTime.now().subtract(const Duration(seconds: 10));
      await repo.upsert(
        Reminder(
          id: 'r1',
          notificationId: 1,
          title: 'Just Passed',
          time: justNow,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      timerService.scheduleNextCheck();
      // Allow microtask queue to flush
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(notifications.shownNow.containsKey(1), isTrue);
    });

    test('skips completed reminders', () async {
      await repo.upsert(
        Reminder(
          id: 'r2',
          notificationId: 2,
          title: 'Completed',
          time: DateTime.now().subtract(const Duration(seconds: 5)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          completedAt: DateTime.now(),
        ),
      );

      timerService.scheduleNextCheck();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(notifications.shownNow, isEmpty);
    });

    test('resetFiredStatus allows re-fire', () async {
      final justNow = DateTime.now().subtract(const Duration(seconds: 10));
      await repo.upsert(
        Reminder(
          id: 'r3',
          notificationId: 3,
          title: 'Resettable',
          time: justNow,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      timerService.scheduleNextCheck();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(notifications.shownNow.containsKey(3), isTrue);

      // Clear and reset
      notifications.reset();
      timerService.resetFiredStatus('r3');
      timerService.scheduleNextCheck();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(notifications.shownNow.containsKey(3), isTrue);
    });

    test('dispose cancels active timer', () {
      timerService.start();
      timerService.dispose();
      // No assertion needed — just verifying no crash.
    });
  });
}
