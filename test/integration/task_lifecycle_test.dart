import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/data/sync_operation_adapter.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_attachment.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:nexus/features/tasks/models/task_repository.dart';

import '../helpers/fake_google_drive_service.dart';
import '../helpers/fake_settings_controller.dart';
import '../helpers/fake_sync_service.dart';

void main() {
  late TaskRepository repo;
  late FakeSyncService syncService;
  late FakeGoogleDriveService driveService;
  late FakeSettingsController settings;
  late TaskController controller;

  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.task)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.taskAttachment)) {
      Hive.registerAdapter(TaskAttachmentAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.syncOperation)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }

    await Hive.openBox<Task>(HiveBoxes.tasks);
    await Hive.openBox<SyncOperation>(HiveBoxes.syncOps);

    repo = TaskRepository();
    syncService = FakeSyncService();
    driveService = FakeGoogleDriveService();
    settings = FakeSettingsController();

    controller = TaskController(
      repo: repo,
      syncService: syncService,
      googleDrive: driveService,
      settings: settings,
      deviceId: 'test-device',
    );
  });

  tearDown(() async {
    controller.dispose();
    await tearDownTestHive();
  });

  group('Task Lifecycle Integration', () {
    test('Create -> Update -> Toggle Complete flow', () async {
      // 1. Create
      final task = await controller.createTask(title: 'Integration Task');
      expect(task.id, isNotEmpty);
      expect(task.title, 'Integration Task');
      expect(task.status, TaskStatus.active.index);

      // Verify in repo
      expect(repo.getById(task.id), isNotNull);

      // 2. Update
      await controller.updateTask(task, title: 'Updated Title');
      expect(task.title, 'Updated Title');
      expect(task.isDirty, isTrue);

      // 3. Toggle Complete
      await controller.toggleCompleted(task, true);
      expect(task.status, TaskStatus.completed.index);
      expect(task.completedAt, isNotNull);

      // Verify persistence
      final stored = repo.getById(task.id)!;
      expect(stored.status, TaskStatus.completed.index);
      expect(stored.completedAt, isNotNull);
    });

    test('Recurring task creates next occurrence on completion', () async {
      // 1. Create Recurring Task (Daily)
      final task = await controller.createTask(
        title: 'Daily Habit',
        recurrence: TaskRecurrenceRule.daily,
        dueDate: DateTime.now(), // Due today
      );

      // 2. Complete it
      await controller.toggleCompleted(task, true);

      // 3. Verify original is completed
      expect(task.status, TaskStatus.completed.index);

      // 4. Verify new task created
      final allTasks = repo.getAll();
      final activeTasks = allTasks
          .where(
            (t) =>
                t.status == TaskStatus.active.index && t.title == 'Daily Habit',
          )
          .toList();

      expect(activeTasks.length, 1);
      final nextTask = activeTasks.first;
      expect(nextTask.id, isNot(task.id));
      expect(nextTask.dueDate!.isAfter(task.dueDate!), isTrue);
    });

    test('Delete task removes from repo and enqueues sync op', () async {
      final task = await controller.createTask(title: 'To Delete');
      syncService.enqueuedOps.clear();

      await controller.deleteTask(task);

      expect(repo.getById(task.id), isNull);
      expect(syncService.enqueuedOps.length, 1);
      expect(
        syncService.enqueuedOps.first.type,
        SyncOperationType.delete.index,
      );
    });
  });
}
