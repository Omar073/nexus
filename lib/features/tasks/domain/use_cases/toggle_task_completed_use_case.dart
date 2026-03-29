import 'dart:async';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/repositories/task_repository_interface.dart';
import 'package:nexus/features/tasks/domain/use_cases/create_task_use_case.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:uuid/uuid.dart';

/// Flips completion and updates ordering.

class ToggleTaskCompletedUseCase {
  ToggleTaskCompletedUseCase(
    this._repo,
    this._syncService, {
    required String deviceId,
    Uuid? uuid,
    CreateTaskUseCase? createTaskUseCase,
  }) : _deviceId = deviceId,
       _uuid = uuid ?? const Uuid(),
       _createTask = createTaskUseCase;

  final TaskRepositoryInterface _repo;
  final SyncService _syncService;
  final String _deviceId;
  final Uuid _uuid;
  final CreateTaskUseCase? _createTask;

  Future<void> call(TaskEntity task, bool completed) async {
    final now = DateTime.now();
    final updated = TaskEntity(
      id: task.id,
      title: task.title,
      description: task.description,
      categoryId: task.categoryId,
      subcategoryId: task.subcategoryId,
      dueDate: task.dueDate,
      startDate: task.startDate,
      priority: task.priority,
      difficulty: task.difficulty,
      status: completed ? TaskStatus.completed.index : TaskStatus.active.index,
      createdAt: task.createdAt,
      updatedAt: now,
      completedAt: completed ? now : null,
      recurringRule: task.recurringRule,
      attachments: task.attachments,
      isDirty: true,
      lastSyncedAt: task.lastSyncedAt,
      syncStatus: SyncStatus.idle.index,
      lastModifiedByDevice: _deviceId,
    );
    await _repo.upsert(updated);
    await _enqueueUpsert(updated);

    if (completed &&
        task.recurringRule != TaskRecurrenceRule.none.index &&
        _createTask != null) {
      final rule = TaskRecurrenceRule.values[task.recurringRule];
      final nextDue = switch (rule) {
        TaskRecurrenceRule.daily => (updated.dueDate ?? DateTime.now()).add(
          const Duration(days: 1),
        ),
        TaskRecurrenceRule.weekly => (updated.dueDate ?? DateTime.now()).add(
          const Duration(days: 7),
        ),
        _ => null,
      };
      if (nextDue != null) {
        final priority = task.priority == null
            ? null
            : TaskPriority.values[task.priority!];
        final difficulty = task.difficulty == null
            ? null
            : TaskDifficulty.values[task.difficulty!];
        await _createTask.call(
          title: updated.title,
          description: updated.description,
          dueDate: nextDue,
          priority: priority,
          difficulty: difficulty,
          recurrence: rule,
        );
      }
    }
  }

  Future<void> _enqueueUpsert(TaskEntity task) async {
    final payload = _repo.getSyncPayload(task.id);
    if (payload == null) return;
    final op = SyncOperation(
      id: _uuid.v4(),
      type: SyncOperationType.update.index,
      entityType: 'task',
      entityId: task.id,
      createdAt: DateTime.now(),
      data: payload,
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }
}
