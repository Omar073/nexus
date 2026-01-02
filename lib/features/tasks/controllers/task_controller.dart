import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/tasks/controllers/task_crud_mixin.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:nexus/features/tasks/models/task_repository.dart';
import 'package:nexus/features/tasks/models/task_sort_option.dart';
import 'package:uuid/uuid.dart';

/// Base class exposing dependencies to mixins.
abstract class TaskControllerBase extends ChangeNotifier {
  TaskRepository get repo;
  SyncService get syncService;
  GoogleDriveService get googleDrive;
  SettingsController get settings;
  String get deviceId;
  Uuid get uuid;

  Future<void> enqueueTaskUpsert(Task task, {required bool isCreate});
  Future<void> deleteTask(Task task);
}

class TaskController extends TaskControllerBase with TaskCrudMixin {
  TaskController({
    required TaskRepository repo,
    required SyncService syncService,
    required GoogleDriveService googleDrive,
    required SettingsController settings,
    required String deviceId,
  }) : _repo = repo,
       _syncService = syncService,
       _googleDrive = googleDrive,
       _settings = settings,
       _deviceId = deviceId,
       _listenable = repo.listenable() {
    _listenable.addListener(_onLocalChanged);
  }

  final TaskRepository _repo;
  final SyncService _syncService;
  final GoogleDriveService _googleDrive;
  final SettingsController _settings;
  final String _deviceId;
  final Listenable _listenable;
  static const _uuid = Uuid();

  // Expose to mixins
  @override
  TaskRepository get repo => _repo;
  @override
  SyncService get syncService => _syncService;
  @override
  GoogleDriveService get googleDrive => _googleDrive;
  @override
  SettingsController get settings => _settings;
  @override
  String get deviceId => _deviceId;
  @override
  Uuid get uuid => _uuid;

  String _query = '';
  String get query => _query;

  bool _filterOverdueOnly = false;
  bool get filterOverdueOnly => _filterOverdueOnly;

  TaskPriority? _filterPriority;
  TaskPriority? get filterPriority => _filterPriority;

  void _onLocalChanged() => notifyListeners();

  @override
  void dispose() {
    _listenable.removeListener(_onLocalChanged);
    super.dispose();
  }

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

  List<Task> tasksForStatus(TaskStatus status) {
    final all = _repo.getAll();

    // Maintenance: purge old completed tasks (best-effort).
    unawaited(_purgeCompletedOlderThanRetention(all));

    final now = DateTime.now();
    final filtered = all
        .where((t) => t.statusEnum == status)
        .where((t) {
          if (_query.isEmpty) return true;
          final q = _query.toLowerCase();
          return t.title.toLowerCase().contains(q) ||
              (t.description?.toLowerCase().contains(q) ?? false);
        })
        .where((t) {
          if (!_filterOverdueOnly) return true;
          final due = t.dueDate;
          return due != null &&
              due.isBefore(now) &&
              t.statusEnum != TaskStatus.completed;
        })
        .where((t) {
          if (_filterPriority == null) return true;
          return t.priorityEnum == _filterPriority;
        })
        .toList();

    // Smart sorting:
    // 1. Urgent tasks (due within 48h) go first, sorted by dueDate
    // 2. High priority tasks go next, sorted by selected option
    // 3. Normal tasks sorted by selected option
    final urgentThreshold = now.add(const Duration(hours: 48));

    final urgent = <Task>[];
    final highPriority = <Task>[];
    final normal = <Task>[];

    for (final t in filtered) {
      final due = t.dueDate;
      final isUrgent =
          due != null && due.isBefore(urgentThreshold) && due.isAfter(now);
      final isHighPriority = t.priorityEnum == TaskPriority.high;

      if (isUrgent) {
        urgent.add(t);
      } else if (isHighPriority) {
        highPriority.add(t);
      } else {
        normal.add(t);
      }
    }

    // Sort urgent by dueDate (soonest first)
    urgent.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    // Sort high priority and normal by selected option
    _applySortOption(highPriority);
    _applySortOption(normal);

    return [...urgent, ...highPriority, ...normal];
  }

  void _applySortOption(List<Task> tasks) {
    final sortOption = _settings.taskSortOption;
    switch (sortOption) {
      case TaskSortOption.newestFirst:
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TaskSortOption.oldestFirst:
        tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case TaskSortOption.recentlyModified:
        tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case TaskSortOption.dueDateAsc:
        tasks.sort((a, b) {
          final ad = a.dueDate;
          final bd = b.dueDate;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
        });
      case TaskSortOption.priorityDesc:
        int priorityScore(TaskPriority? p) => switch (p) {
          TaskPriority.high => 3,
          TaskPriority.medium => 2,
          TaskPriority.low => 1,
          null => 0,
        };
        tasks.sort(
          (a, b) => priorityScore(
            b.priorityEnum,
          ).compareTo(priorityScore(a.priorityEnum)),
        );
    }
  }

  Future<void> _purgeCompletedOlderThanRetention(List<Task> all) async {
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
      await deleteTask(t);
    }
  }

  Task? byId(String id) => _repo.getById(id);

  Task? get highestPriorityActive {
    Task? best;
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

  /// Clears categoryId on all tasks that belong to the given category IDs.
  Future<void> clearCategoryOnTasks(List<String> categoryIds) async {
    final all = _repo.getAll();
    for (final task in all) {
      if (categoryIds.contains(task.categoryId) ||
          categoryIds.contains(task.subcategoryId)) {
        if (categoryIds.contains(task.categoryId)) {
          task.categoryId = null;
        }
        if (categoryIds.contains(task.subcategoryId)) {
          task.subcategoryId = null;
        }
        task.updatedAt = DateTime.now();
        await task.save();
      }
    }
  }
}
