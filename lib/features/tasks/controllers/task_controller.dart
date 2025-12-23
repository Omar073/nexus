import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_attachment.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:nexus/features/tasks/models/task_repository.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class TaskController extends ChangeNotifier {
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

    // Sort: priority desc, dueDate asc, updatedAt desc.
    int priorityScore(TaskPriority? p) => switch (p) {
      TaskPriority.high => 3,
      TaskPriority.medium => 2,
      TaskPriority.low => 1,
      null => 0,
    };

    filtered.sort((a, b) {
      final p = priorityScore(
        b.priorityEnum,
      ).compareTo(priorityScore(a.priorityEnum));
      if (p != 0) return p;
      final ad = a.dueDate;
      final bd = b.dueDate;
      if (ad != null && bd != null) {
        final c = ad.compareTo(bd);
        if (c != 0) return c;
      } else if (ad == null && bd != null) {
        return 1;
      } else if (ad != null && bd == null) {
        return -1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return filtered;
  }

  Future<Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskDifficulty? difficulty,
    TaskRecurrenceRule recurrence = TaskRecurrenceRule.none,
  }) async {
    final now = DateTime.now();
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      description: (description?.trim().isEmpty ?? true)
          ? null
          : description?.trim(),
      status: TaskStatus.active.index,
      createdAt: now,
      updatedAt: now,
      dueDate: dueDate,
      priority: priority?.index,
      difficulty: difficulty?.index,
      recurringRule: recurrence.index,
      lastModifiedByDevice: _deviceId,
      isDirty: true,
      syncStatus: SyncStatus.idle.index,
    );
    await _repo.upsert(task);
    await _enqueueTaskUpsert(task, isCreate: true);
    return task;
  }

  Future<void> updateTask(
    Task task, {
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskDifficulty? difficulty,
    TaskRecurrenceRule? recurrence,
  }) async {
    final now = DateTime.now();
    if (title != null) task.title = title.trim();
    if (description != null) {
      task.description = description.trim().isEmpty ? null : description.trim();
    }
    if (dueDate != null) task.dueDate = dueDate;
    if (priority != null) task.priorityEnum = priority;
    if (difficulty != null) task.difficultyEnum = difficulty;
    if (recurrence != null) task.recurringRuleEnum = recurrence;
    task.updatedAt = now;
    task.lastModifiedByDevice = _deviceId;
    task.isDirty = true;
    task.syncStatusEnum = SyncStatus.idle;
    await task.save();
    await _enqueueTaskUpsert(task, isCreate: false);
  }

  Future<void> deleteTask(Task task) async {
    await _repo.delete(task.id);
    final op = SyncOperation(
      id: _uuid.v4(),
      type: SyncOperationType.delete.index,
      entityType: 'task',
      entityId: task.id,
      createdAt: DateTime.now(),
      data: null,
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }

  Future<void> toggleCompleted(Task task, bool completed) async {
    final now = DateTime.now();
    task.statusEnum = completed ? TaskStatus.completed : TaskStatus.active;
    task.completedAt = completed ? now : null;
    task.updatedAt = now;
    task.lastModifiedByDevice = _deviceId;
    task.isDirty = true;
    task.syncStatusEnum = SyncStatus.idle;
    await task.save();
    await _enqueueTaskUpsert(task, isCreate: false);

    if (completed && task.recurringRuleEnum != TaskRecurrenceRule.none) {
      await _createNextRecurring(task);
    }
  }

  Future<void> addAttachment(Task task, TaskAttachment attachment) async {
    task.attachments = [...task.attachments, attachment];
    task.updatedAt = DateTime.now();
    task.lastModifiedByDevice = _deviceId;
    task.isDirty = true;
    task.syncStatusEnum = SyncStatus.idle;
    await task.save();

    // Best-effort upload to Google Drive if authenticated + localUri exists.
    if (attachment.localUri != null) {
      try {
        final file = File(attachment.localUri!);
        if (await file.exists()) {
          // This will throw DriveAuthRequiredException if not authenticated
          final driveId = await _googleDrive.uploadTaskFile(
            taskId: task.id,
            file: file,
            filename: file.uri.pathSegments.last,
            mimeType: attachment.mimeType,
          );
          attachment.driveFileId = driveId;
          attachment.uploaded = true;
          await task.save();
        }
      } catch (e) {
        // Re-throw DriveAuthRequiredException so view can handle it
        // Other errors are silently ignored - attachment is saved locally
        rethrow;
      }
    }

    await _enqueueTaskUpsert(task, isCreate: false);
  }

  Future<void> _createNextRecurring(Task completedTask) async {
    final rule = completedTask.recurringRuleEnum;
    final nextDue = switch (rule) {
      TaskRecurrenceRule.daily => (completedTask.dueDate ?? DateTime.now()).add(
        const Duration(days: 1),
      ),
      TaskRecurrenceRule.weekly =>
        (completedTask.dueDate ?? DateTime.now()).add(const Duration(days: 7)),
      _ => null,
    };
    if (nextDue == null) return;

    await createTask(
      title: completedTask.title,
      description: completedTask.description,
      dueDate: nextDue,
      priority: completedTask.priorityEnum,
      difficulty: completedTask.difficultyEnum,
      recurrence: completedTask.recurringRuleEnum,
    );
  }

  Future<void> _enqueueTaskUpsert(Task task, {required bool isCreate}) async {
    final op = SyncOperation(
      id: _uuid.v4(),
      type: (isCreate ? SyncOperationType.create : SyncOperationType.update)
          .index,
      entityType: 'task',
      entityId: task.id,
      createdAt: DateTime.now(),
      data: task.toFirestoreJson(),
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }

  Future<void> _purgeCompletedOlderThanRetention(List<Task> all) async {
    // Only purge if auto-delete is enabled
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

    // Avoid heavy purge loops: cap per call.
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
}
