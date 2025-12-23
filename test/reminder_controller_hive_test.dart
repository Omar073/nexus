import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive_boxes.dart';
import 'package:nexus/core/services/notifications/reminder_notifications.dart';
import 'package:nexus/features/reminders/controllers/reminder_controller.dart';
import 'package:nexus/features/reminders/models/reminder.dart';
import 'package:nexus/features/reminders/models/reminder_repository.dart';

class _FakeNotificationService implements ReminderNotifications {
  final scheduled = <int, DateTime>{};
  final canceled = <int>[];

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    scheduled[id] = when;
  }

  @override
  Future<void> cancel(int id) async {
    canceled.add(id);
  }
}

void main() {
  test(
    'ReminderController schedules on create and cancels on delete',
    () async {
      await setUpTestHive();
      Hive.registerAdapter(ReminderAdapter());
      await Hive.openBox<Reminder>(HiveBoxes.reminders);

      final repo = ReminderRepository();
      final notifications = _FakeNotificationService();

      final controller = ReminderController(
        repo: repo,
        notifications: notifications,
      );

      final when = DateTime.now().add(const Duration(minutes: 10));
      final r = await controller.create(title: 'Test', time: when);

      expect(notifications.scheduled.containsKey(r.notificationId), true);

      await controller.delete(r);
      expect(notifications.canceled.contains(r.notificationId), true);

      await tearDownTestHive();
    },
  );
}
