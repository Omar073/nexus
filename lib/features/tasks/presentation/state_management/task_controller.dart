import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:uuid/uuid.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/tasks/presentation/utils/task_sorting_helper.dart';
import 'package:nexus/features/tasks/domain/entities/task_attachment_entity.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/repositories/task_repository_interface.dart';
import 'package:nexus/features/tasks/domain/use_cases/add_task_attachment_use_case.dart';
import 'package:nexus/features/tasks/domain/use_cases/clear_category_on_tasks_use_case.dart';
import 'package:nexus/features/tasks/domain/use_cases/create_task_use_case.dart';
import 'package:nexus/features/tasks/domain/use_cases/delete_task_use_case.dart';
import 'package:nexus/features/tasks/domain/use_cases/toggle_task_completed_use_case.dart';
import 'package:nexus/features/tasks/domain/use_cases/update_task_use_case.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:nexus/features/tasks/presentation/extensions/task_entity_extensions.dart';

/// Central tasks state: tabs, categories, selection, and ordering.
/// Drives [TasksScreen], editor sheets, and bulk actions via [TaskBulkActions].

class TaskController extends ChangeNotifier {
  TaskController({
    required TaskRepositoryInterface repo,
    required SyncService syncService,
    required GoogleDriveService googleDrive,
    required SettingsController settings,
    required String deviceId,
  }) : _repo = repo,
       _syncService = syncService,
       _settings = settings,
       _sortingHelper = TaskSortingHelper(settings),
       _createTask = CreateTaskUseCase(repo, syncService, deviceId: deviceId),
       _updateTask = UpdateTaskUseCase(repo, syncService, deviceId: deviceId),
       _deleteTask = DeleteTaskUseCase(repo, syncService),
       _toggleCompleted = ToggleTaskCompletedUseCase(
         repo,
         syncService,
         deviceId: deviceId,
         createTaskUseCase: CreateTaskUseCase(
           repo,
           syncService,
           deviceId: deviceId,
         ),
       ),
       _addAttachment = AddTaskAttachmentUseCase(
         repo,
         syncService,
         googleDrive,
         deviceId: deviceId,
       ),
       _clearCategory = ClearCategoryOnTasksUseCase(
         repo,
         syncService,
         deviceId: deviceId,
       ) {
    _subscription = repo.changes.listen((_) => notifyListeners());
  }

  final TaskRepositoryInterface _repo;
  final SyncService _syncService;
  final SettingsController _settings;
  StreamSubscription<void>? _subscription;
  final TaskSortingHelper _sortingHelper;
  final CreateTaskUseCase _createTask;
  final UpdateTaskUseCase _updateTask;
  final DeleteTaskUseCase _deleteTask;
  final ToggleTaskCompletedUseCase _toggleCompleted;
  final AddTaskAttachmentUseCase _addAttachment;
  final ClearCategoryOnTasksUseCase _clearCategory;

  String _query = '';
  String get query => _query;

  bool _filterOverdueOnly = false;
  bool get filterOverdueOnly => _filterOverdueOnly;

  TaskPriority? _filterPriority;
  TaskPriority? get filterPriority => _filterPriority;

  void setQuery(String value) {
    _query = value.trim();
    notifyListeners();
  }

  void setOverdueOnly(bool v) {
    _filterOverdueOnly = v;
    notifyListeners();
  }

  void setPriorityFilter(TaskPriority? v) {
    _filterPriority = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  TaskEntity? byId(String id) => _repo.getById(id);

  TaskEntity? get highestPriorityActive {
    TaskEntity? best;
    for (final t in _repo.getAll()) {
      if (t.statusEnum == TaskStatus.completed) continue;
      if (best == null) {
        best = t;
        continue;
      }
      final tp = t.priority ?? -1;
      final bp = best.priority ?? -1;
      if (tp > bp) best = t;
    }
    return best;
  }

  List<TaskEntity> tasksForStatus(TaskStatus status) {
    final all = _repo.getAll();
    unawaited(_purgeCompletedOlderThanRetention(all));
    final filtered = _applyFilters(all, status);
    return _sortingHelper.applySorting(filtered);
  }

  Future<TaskEntity> createTask({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskDifficulty? difficulty,
    TaskRecurrenceRule recurrence = TaskRecurrenceRule.none,
    String? categoryId,
    String? subcategoryId,
  }) => _createTask.call(
    title: title,
    description: description,
    startDate: startDate,
    dueDate: dueDate,
    priority: priority,
    difficulty: difficulty,
    recurrence: recurrence,
    categoryId: categoryId,
    subcategoryId: subcategoryId,
  );

  Future<void> updateTask(
    TaskEntity task, {
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskDifficulty? difficulty,
    TaskRecurrenceRule? recurrence,
    String? categoryId,
    String? subcategoryId,
  }) => _updateTask.call(
    task,
    title: title,
    description: description,
    startDate: startDate,
    dueDate: dueDate,
    priority: priority,
    difficulty: difficulty,
    recurrence: recurrence,
    categoryId: categoryId,
    subcategoryId: subcategoryId,
  );

  Future<void> deleteTask(TaskEntity task) => _deleteTask.call(task);

  /// Restore a previously deleted task (e.g. for undo).
  Future<void> restoreTask(TaskEntity task) async {
    await _repo.upsert(task);
    final payload = _repo.getSyncPayload(task.id);
    if (payload != null) {
      final op = SyncOperation(
        id: const Uuid().v4(),
        type: SyncOperationType.create.index,
        entityType: 'task',
        entityId: task.id,
        createdAt: DateTime.now(),
        data: payload,
      );
      await _syncService.enqueueOperation(op);
      unawaited(_syncService.syncOnce());
    }
  }

  Future<void> toggleCompleted(TaskEntity task, bool completed) =>
      _toggleCompleted.call(task, completed);

  Future<void> addAttachment(
    TaskEntity task,
    TaskAttachmentEntity attachment,
  ) => _addAttachment.call(task, attachment);

  Future<void> clearCategoryOnTasks(List<String> categoryIds) =>
      _clearCategory.call(categoryIds);

  List<TaskEntity> _applyFilters(List<TaskEntity> all, TaskStatus status) {
    final now = DateTime.now();
    return all
        .where((t) => t.statusEnum == status)
        .where((t) => _matchesQuery(t))
        .where((t) => _matchesOverdueFilter(t, now))
        .where((t) => _matchesPriorityFilter(t))
        .toList();
  }

  bool _matchesQuery(TaskEntity t) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return t.title.toLowerCase().contains(q) ||
        (t.description?.toLowerCase().contains(q) ?? false);
  }

  bool _matchesOverdueFilter(TaskEntity t, DateTime now) {
    if (!_filterOverdueOnly) return true;
    final due = t.dueDate;
    return due != null &&
        due.isBefore(now) &&
        t.statusEnum != TaskStatus.completed;
  }

  bool _matchesPriorityFilter(TaskEntity t) {
    if (_filterPriority == null) return true;
    return t.priorityEnum == _filterPriority;
  }

  Future<void> _purgeCompletedOlderThanRetention(List<TaskEntity> all) async {
    if (!_settings.autoDeleteCompletedTasks) return;
    final days = _settings.completedRetentionDays;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final purge = all.where((t) => t.statusEnum == TaskStatus.completed).where((
      t,
    ) {
      final completedAt = t.completedAt;
      return completedAt != null && completedAt.isBefore(cutoff);
    }).toList();
    if (purge.isEmpty) return;
    for (final t in purge.take(50)) {
      await _deleteTask.call(t);
    }
  }
}
