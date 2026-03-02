import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/reminders/presentation/state_management/reminder_controller.dart';
import 'package:nexus/features/reminders/data/models/reminder.dart';
import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';
import 'package:nexus/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:nexus/features/reminders/data/mappers/reminder_mapper.dart';

import '../helpers/fake_notification_service.dart';

/// Integration test: Reminder creation → notification scheduling →
/// snooze → complete.
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
      final completedReminder = controller.reminders.firstWhere(
        (r) => r.id == reminder.id,
      );
      expect(completedReminder.completedAt, isNotNull);
      expect(notifications.canceled, contains(reminder.notificationId));
    });

    test('uncomplete → reschedule for future reminders', () async {
      final future = DateTime.now().add(const Duration(hours: 3));
      final reminder = await controller.create(title: 'Later', time: future);
      await controller.complete(reminder);
      notifications.reset();

      await controller.uncomplete(reminder);

      final uncompletedReminder = controller.reminders.firstWhere(
        (r) => r.id == reminder.id,
      );
      expect(uncompletedReminder.completedAt, isNull);
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
      await repo.upsert(ReminderMapper.toEntity(old));

      // Re-create controller (runs cleanup in constructor)
      controller.dispose();
      controller = ReminderController(
        repo: repo,
        notifications: notifications,
        syncService: syncService,
      );

      // Old completed reminder should be cleaned up
      expect(controller.reminders.any((r) => r.id == 'old-r'), isFalse);
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
