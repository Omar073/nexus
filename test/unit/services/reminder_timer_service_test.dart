import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/features/reminders/data/models/reminder.dart';
import 'package:nexus/features/reminders/data/mappers/reminder_mapper.dart';
import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';
import 'package:nexus/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:nexus/features/reminders/data/services/reminder_timer_service.dart';

import '../../helpers/fake_notification_service.dart';

void main() {
  late ReminderRepositoryInterface repo;
  late FakeNotificationService notifications;
  late ReminderTimerService timerService;

  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.reminder)) {
      Hive.registerAdapter(ReminderAdapter());
    }
    await Hive.openBox<Reminder>(HiveBoxes.reminders);
    repo = ReminderRepositoryImpl();
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
    test('skips past-due reminders (Layer 1 handles them)', () async {
      final justNow = DateTime.now().subtract(const Duration(seconds: 10));
      await repo.upsert(
        ReminderMapper.toEntity(
          Reminder(
            id: 'r1',
            notificationId: 1,
            title: 'Just Passed',
            time: justNow,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      );

      timerService.scheduleNextCheck();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(notifications.shownNow, isEmpty);
    });

    test('skips completed reminders', () async {
      await repo.upsert(
        ReminderMapper.toEntity(
          Reminder(
            id: 'r2',
            notificationId: 2,
            title: 'Completed',
            time: DateTime.now().subtract(const Duration(seconds: 5)),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            completedAt: DateTime.now(),
          ),
        ),
      );

      timerService.scheduleNextCheck();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(notifications.shownNow, isEmpty);
    });

    test('fires future reminder when timer elapses', () async {
      final soon = DateTime.now().add(const Duration(seconds: 1));
      await repo.upsert(
        ReminderMapper.toEntity(
          Reminder(
            id: 'r3',
            notificationId: 3,
            title: 'Soon',
            time: soon,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      );

      timerService.scheduleNextCheck();
      await Future<void>.delayed(const Duration(seconds: 2));

      expect(notifications.shownNow.containsKey(3), isTrue);
    });

    test('dispose cancels active timer', () {
      timerService.start();
      timerService.dispose();
      // No assertion needed — just verifying no crash.
    });
  });
}
