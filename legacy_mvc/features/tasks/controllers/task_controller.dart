import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/tasks/controllers/helpers/task_sorting_helper.dart';
import 'package:nexus/features/tasks/controllers/task_controller_base.dart';
import 'package:nexus/features/tasks/controllers/task_crud_mixin.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:nexus/features/tasks/models/task_repository.dart';
import 'package:uuid/uuid.dart';

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
       _listenable = repo.listenable(),
       _sortingHelper = TaskSortingHelper(settings) {
    _listenable.addListener(_onLocalChanged);
  }

  // --------------------------------------------------------------------------
  // Dependencies
  // --------------------------------------------------------------------------

  final TaskRepository _repo;
  final SyncService _syncService;
  final GoogleDriveService _googleDrive;
  final SettingsController _settings;
  final String _deviceId;
  final Listenable _listenable;
  final TaskSortingHelper _sortingHelper;
  static const _uuid = Uuid();

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

  // --------------------------------------------------------------------------
  // Filter State
  // --------------------------------------------------------------------------

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

  // --------------------------------------------------------------------------
  // Lifecycle
  // --------------------------------------------------------------------------

  void _onLocalChanged() => notifyListeners();

  @override
  void dispose() {
    _listenable.removeListener(_onLocalChanged);
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Queries
  // --------------------------------------------------------------------------

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

  List<Task> tasksForStatus(TaskStatus status) {
    final all = _repo.getAll();

    // Maintenance: purge old completed tasks (best-effort).
    unawaited(_purgeCompletedOlderThanRetention(all));

    final filtered = _applyFilters(all, status);
    return _sortingHelper.applySorting(filtered);
  }

  // --------------------------------------------------------------------------
  // Category Operations
  // --------------------------------------------------------------------------

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

  // --------------------------------------------------------------------------
  // Private: Filtering
  // --------------------------------------------------------------------------

  List<Task> _applyFilters(List<Task> all, TaskStatus status) {
    final now = DateTime.now();
    return all
        .where((t) => t.statusEnum == status)
        .where((t) => _matchesQuery(t))
        .where((t) => _matchesOverdueFilter(t, now))
        .where((t) => _matchesPriorityFilter(t))
        .toList();
  }

  bool _matchesQuery(Task t) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return t.title.toLowerCase().contains(q) ||
        (t.description?.toLowerCase().contains(q) ?? false);
  }

  bool _matchesOverdueFilter(Task t, DateTime now) {
    if (!_filterOverdueOnly) return true;
    final due = t.dueDate;
    return due != null &&
        due.isBefore(now) &&
        t.statusEnum != TaskStatus.completed;
  }

  bool _matchesPriorityFilter(Task t) {
    if (_filterPriority == null) return true;
    return t.priorityEnum == _filterPriority;
  }

  // --------------------------------------------------------------------------
  // Private: Maintenance
  // --------------------------------------------------------------------------

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
}
