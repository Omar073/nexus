import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/features/reminders/controllers/reminder_controller.dart';
import 'package:nexus/features/reminders/models/reminder.dart';
import 'package:nexus/features/reminders/models/reminder_repository.dart';

import '../helpers/fake_notification_service.dart';

/// Integration test: Reminder creation → notification scheduling →
/// snooze → complete.
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

  group('Reminder scheduling integration', () {
    test('create → snooze → complete lifecycle', () async {
      // 1. Create
      final when = DateTime.now().add(const Duration(hours: 1));
      final reminder = await controller.create(title: 'Meeting', time: when);
      expect(
        notifications.scheduled.containsKey(reminder.notificationId),
        isTrue,
      );

      // 2. Snooze by 5 min
      notifications.reset();
      await controller.snooze(reminder);
      expect(
        notifications.scheduled.containsKey(reminder.notificationId),
        isTrue,
      );

      // 3. Complete
      notifications.reset();
      await controller.complete(reminder);
      expect(reminder.completedAt, isNotNull);
      expect(notifications.canceled, contains(reminder.notificationId));
    });

    test('uncomplete → reschedule for future reminders', () async {
      final future = DateTime.now().add(const Duration(hours: 3));
      final reminder = await controller.create(title: 'Later', time: future);
      await controller.complete(reminder);
      notifications.reset();

      await controller.uncomplete(reminder);

      expect(reminder.completedAt, isNull);
      expect(
        notifications.scheduled.containsKey(reminder.notificationId),
        isTrue,
      );
    });

    test('cleanup removes old completed reminders', () async {
      // Create a reminder completed yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final old = Reminder(
        id: 'old-r',
        notificationId: 999,
        title: 'Old reminder',
        time: yesterday,
        createdAt: yesterday,
        updatedAt: yesterday,
        completedAt: yesterday.subtract(const Duration(hours: 1)),
      );
      await repo.upsert(old);

      // Re-create controller (runs cleanup in constructor)
      controller.dispose();
      controller = ReminderController(repo: repo, notifications: notifications);

      // Old completed reminder should be cleaned up
      expect(controller.reminders.any((r) => r.id == 'old-r'), isFalse);
    });
  });
}
