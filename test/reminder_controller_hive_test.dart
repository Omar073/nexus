import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/notifications/reminder_notifications.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/reminders/data/models/reminder.dart';
import 'package:nexus/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:nexus/features/reminders/presentation/state_management/reminder_controller.dart';

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

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    scheduled[id] = DateTime.now();
  }
}

void main() {
  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.reminder)) {
      Hive.registerAdapter(ReminderAdapter());
    }
    await Hive.openBox<Reminder>(HiveBoxes.reminders);
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  test(
    'ReminderController schedules on create and cancels on delete',
    () async {
      final repo = ReminderRepositoryImpl();
      final notifications = _FakeNotificationService();
      final syncService = _FakeSyncService();

      final controller = ReminderController(
        repo: repo,
        notifications: notifications,
        syncService: syncService,
      );

      final when = DateTime.now().add(const Duration(minutes: 10));
      final r = await controller.create(title: 'Test', time: when);

      expect(notifications.scheduled.containsKey(r.notificationId), true);

      await controller.delete(r);
      expect(notifications.canceled.contains(r.notificationId), true);
    },
  );

  test('ReminderController can uncomplete a reminder', () async {
    final repo = ReminderRepositoryImpl();
    final notifications = _FakeNotificationService();
    final syncService = _FakeSyncService();

    final controller = ReminderController(
      repo: repo,
      notifications: notifications,
      syncService: syncService,
    );

    // Create a reminder in the future
    final futureTime = DateTime.now().add(const Duration(minutes: 10));
    final r = await controller.create(title: 'Future', time: futureTime);

    // Complete it
    await controller.complete(r);
    final completed = controller.reminders.firstWhere((x) => x.id == r.id);
    expect(completed.completedAt, isNotNull);
    expect(notifications.canceled.contains(r.notificationId), true);

    // Clear tracking
    notifications.scheduled.clear();
    notifications.canceled.clear();

    // Uncomplete it
    await controller.uncomplete(r);
    final uncompleted = controller.reminders.firstWhere((x) => x.id == r.id);
    expect(uncompleted.completedAt, isNull);
    // Should be rescheduled because it's in the future
    expect(notifications.scheduled.containsKey(r.notificationId), true);
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
