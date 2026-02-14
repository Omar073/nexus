import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/features/reminders/controllers/reminder_controller.dart';
import 'package:nexus/features/reminders/models/reminder.dart';
import 'package:nexus/features/reminders/models/reminder_repository.dart';

import '../../helpers/fake_notification_service.dart';

void main() {
  late ReminderRepository repo;
  late FakeNotificationService notifications;
  late ReminderController controller;

  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.reminder)) {
      Hive.registerAdapter(ReminderAdapter());
    }
    await Hive.openBox<Reminder>(HiveBoxes.reminders);
    repo = ReminderRepository();
    notifications = FakeNotificationService();
    controller = ReminderController(repo: repo, notifications: notifications);
  });

  tearDown(() async {
    controller.dispose();
    await tearDownTestHive();
  });

  group('ReminderController', () {
    test('create schedules a notification', () async {
      final when = DateTime.now().add(const Duration(hours: 1));

      final reminder = await controller.create(title: 'Test', time: when);

      expect(controller.reminders, contains(reminder));
      expect(
        notifications.scheduled.containsKey(reminder.notificationId),
        isTrue,
      );
    });

    test('complete cancels notification', () async {
      final when = DateTime.now().add(const Duration(hours: 1));
      final reminder = await controller.create(
        title: 'Completable',
        time: when,
      );

      await controller.complete(reminder);

      expect(reminder.completedAt, isNotNull);
      expect(notifications.canceled, contains(reminder.notificationId));
    });

    test('uncomplete reschedules if in future', () async {
      final future = DateTime.now().add(const Duration(hours: 2));
      final reminder = await controller.create(title: 'Future', time: future);
      await controller.complete(reminder);
      notifications.reset();

      await controller.uncomplete(reminder);

      expect(reminder.completedAt, isNull);
      expect(
        notifications.scheduled.containsKey(reminder.notificationId),
        isTrue,
      );
    });

    test('snooze updates time and reschedules', () async {
      final now = DateTime.now();
      final reminder = await controller.create(
        title: 'Snoozeable',
        time: now.add(const Duration(minutes: 1)),
      );
      notifications.reset();

      await controller.snooze(reminder, minutes: 10);

      expect(reminder.time.isAfter(now), isTrue);
      expect(notifications.canceled, contains(reminder.notificationId));
      expect(
        notifications.scheduled.containsKey(reminder.notificationId),
        isTrue,
      );
    });

    test('delete cancels notification and removes', () async {
      final reminder = await controller.create(
        title: 'Deletable',
        time: DateTime.now().add(const Duration(hours: 1)),
      );
      notifications.reset();

      await controller.delete(reminder);

      expect(controller.reminders.any((r) => r.id == reminder.id), isFalse);
      expect(notifications.canceled, contains(reminder.notificationId));
    });
  });
}
