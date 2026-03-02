import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/reminders/data/models/reminder.dart';
import 'package:nexus/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';
import 'package:nexus/features/reminders/presentation/state_management/reminder_controller.dart';

import '../../helpers/fake_notification_service.dart';

void main() {
  late ReminderRepositoryInterface repo;
  late FakeNotificationService notifications;
  late SyncService syncService;
  late ReminderController controller;

  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.reminder)) {
      Hive.registerAdapter(ReminderAdapter());
    }
    await Hive.openBox<Reminder>(HiveBoxes.reminders);
    repo = ReminderRepositoryImpl();
    notifications = FakeNotificationService();
    syncService = _FakeSyncService();
    controller = ReminderController(
      repo: repo,
      notifications: notifications,
      syncService: syncService,
    );
  });

  tearDown(() async {
    controller.dispose();
    await tearDownTestHive();
  });

  group('ReminderController', () {
    test('create schedules a notification', () async {
      final when = DateTime.now().add(const Duration(hours: 1));

      final reminder = await controller.create(title: 'Test', time: when);

      expect(controller.reminders.any((r) => r.id == reminder.id), isTrue);
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

      final completed = controller.reminders.firstWhere(
        (r) => r.id == reminder.id,
      );
      expect(completed.completedAt, isNotNull);
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

class _FakeSyncService extends SyncService {
  _FakeSyncService() : super(connectivity: ConnectivityService());

  @override
  Future<void> enqueueOperation(SyncOperation op) async {
    // no-op for tests
  }

  @override
  Future<void> syncOnce() async {
    // no-op for tests
  }
}
