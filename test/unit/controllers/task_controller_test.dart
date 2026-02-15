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

import '../../helpers/fake_google_drive_service.dart';
import '../../helpers/fake_settings_controller.dart';
import '../../helpers/fake_sync_service.dart';

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

  Task _makeTask({
    required String id,
    required String title,
    String? description,
    TaskStatus status = TaskStatus.active,
    int? priority,
    DateTime? dueDate,
    DateTime? completedAt,
    String? categoryId,
    String? subcategoryId,
  }) {
    final now = DateTime.now();
    return Task(
      id: id,
      title: title,
      description: description,
      status: status.index,
      priority: priority,
      dueDate: dueDate,
      completedAt: completedAt,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      createdAt: now,
      updatedAt: now,
      lastModifiedByDevice: 'test-device',
    );
  }

  group('TaskController', () {
    test('tasksForStatus returns filtered list by status', () async {
      await repo.upsert(_makeTask(id: 't1', title: 'Active'));
      await repo.upsert(
        _makeTask(id: 't2', title: 'Done', status: TaskStatus.completed),
      );

      final active = controller.tasksForStatus(TaskStatus.active);
      final completed = controller.tasksForStatus(TaskStatus.completed);

      expect(active.length, 1);
      expect(active.first.title, 'Active');
      expect(completed.length, 1);
      expect(completed.first.title, 'Done');
    });

    test('setQuery filters by title/description substring', () async {
      await repo.upsert(_makeTask(id: 't1', title: 'Buy groceries'));
      await repo.upsert(
        _makeTask(
          id: 't2',
          title: 'Read book',
          description: 'groceries list inside',
        ),
      );
      await repo.upsert(_makeTask(id: 't3', title: 'Exercise'));

      controller.setQuery('groceries');
      final result = controller.tasksForStatus(TaskStatus.active);

      expect(result.length, 2);
      expect(result.map((t) => t.id), containsAll(['t1', 't2']));
    });

    test('setOverdueOnly excludes non-overdue tasks', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final tomorrow = DateTime.now().add(const Duration(days: 3));

      await repo.upsert(
        _makeTask(id: 't1', title: 'Overdue', dueDate: yesterday),
      );
      await repo.upsert(
        _makeTask(id: 't2', title: 'Upcoming', dueDate: tomorrow),
      );
      await repo.upsert(_makeTask(id: 't3', title: 'No due date'));

      controller.setOverdueOnly(true);
      final result = controller.tasksForStatus(TaskStatus.active);

      expect(result.length, 1);
      expect(result.first.id, 't1');
    });

    test('setPriorityFilter filters by priority enum', () async {
      await repo.upsert(
        _makeTask(id: 't1', title: 'Low', priority: TaskPriority.low.index),
      );
      await repo.upsert(
        _makeTask(id: 't2', title: 'High', priority: TaskPriority.high.index),
      );
      await repo.upsert(_makeTask(id: 't3', title: 'None'));

      controller.setPriorityFilter(TaskPriority.high);
      final result = controller.tasksForStatus(TaskStatus.active);

      expect(result.length, 1);
      expect(result.first.id, 't2');
    });

    test('byId returns correct task or null', () async {
      await repo.upsert(_makeTask(id: 't1', title: 'Exists'));

      expect(controller.byId('t1')?.title, 'Exists');
      expect(controller.byId('missing'), isNull);
    });

    test('highestPriorityActive skips completed tasks', () async {
      await repo.upsert(
        _makeTask(
          id: 't1',
          title: 'Completed high',
          status: TaskStatus.completed,
          priority: TaskPriority.high.index,
        ),
      );
      await repo.upsert(
        _makeTask(
          id: 't2',
          title: 'Active medium',
          priority: TaskPriority.medium.index,
        ),
      );
      await repo.upsert(
        _makeTask(
          id: 't3',
          title: 'Active low',
          priority: TaskPriority.low.index,
        ),
      );

      final best = controller.highestPriorityActive;

      expect(best, isNotNull);
      expect(best!.id, 't2');
    });

    test('clearCategoryOnTasks nullifies matching IDs', () async {
      await repo.upsert(
        _makeTask(
          id: 't1',
          title: 'Categorised',
          categoryId: 'cat-1',
          subcategoryId: 'sub-1',
        ),
      );
      await repo.upsert(
        _makeTask(id: 't2', title: 'Other', categoryId: 'cat-2'),
      );

      await controller.clearCategoryOnTasks(['cat-1', 'sub-1']);

      final t1 = repo.getById('t1')!;
      final t2 = repo.getById('t2')!;

      expect(t1.categoryId, isNull);
      expect(t1.subcategoryId, isNull);
      expect(t2.categoryId, 'cat-2');
    });

    test(
      'purgeCompletedOlderThanRetention deletes old completed tasks',
      () async {
        settings.autoDeleteCompletedTasks = true;
        settings.completedRetentionDays = 30;

        final oldDate = DateTime.now().subtract(const Duration(days: 60));
        await repo.upsert(
          _makeTask(
            id: 't-old',
            title: 'Old completed',
            status: TaskStatus.completed,
            completedAt: oldDate,
          ),
        );
        await repo.upsert(_makeTask(id: 't-active', title: 'Still active'));

        // tasksForStatus triggers the purge internally.
        controller.tasksForStatus(TaskStatus.active);

        // Give the async purge a moment to run.
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(repo.getById('t-old'), isNull);
        expect(repo.getById('t-active'), isNotNull);
      },
    );
  });
}
