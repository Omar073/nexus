import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/features/reminders/data/models/reminder.dart';

import '../../helpers/fake_notification_service.dart';

// Import the testable function from workmanager_dispatcher.
import 'package:nexus/features/reminders/data/services/reminder_workmanager_callback.dart';

void main() {
  late Box<Reminder> box;
  late FakeNotificationService notifications;

  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.reminder)) {
      Hive.registerAdapter(ReminderAdapter());
    }
    box = await Hive.openBox<Reminder>(HiveBoxes.reminders);
    notifications = FakeNotificationService();
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('handleBackgroundCheck', () {
    test('skips completed reminders', () async {
      await box.put(
        'r1',
        Reminder(
          id: 'r1',
          notificationId: 100,
          title: 'Done',
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          completedAt: DateTime.now(),
        ),
      );

      await handleBackgroundCheck(box: box, notifications: notifications);

      // handleBackgroundCheck expects ReminderNotifications; our
      // fake implements it. We verify the fake was not called.
      expect(notifications.shownNow, isEmpty);
    });

    test('fires reminders due within 46 minutes', () async {
      final dueTime = DateTime.now().subtract(const Duration(minutes: 30));
      await box.put(
        'r2',
        Reminder(
          id: 'r2',
          notificationId: 200,
          title: 'Due Recently',
          time: dueTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await handleBackgroundCheck(box: box, notifications: notifications);

      expect(notifications.shownNow.containsKey(200), isTrue);
    });

    test('ignores reminders older than 46 minutes', () async {
      final oldTime = DateTime.now().subtract(const Duration(hours: 2));
      await box.put(
        'r3',
        Reminder(
          id: 'r3',
          notificationId: 300,
          title: 'Old',
          time: oldTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await handleBackgroundCheck(box: box, notifications: notifications);

      expect(notifications.shownNow, isEmpty);
    });
  });
}
