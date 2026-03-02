import 'dart:async';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/repositories/task_repository_interface.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:uuid/uuid.dart';

class UpdateTaskUseCase {
  UpdateTaskUseCase(
    this._repo,
    this._syncService, {
    required String deviceId,
    Uuid? uuid,
  }) : _deviceId = deviceId,
       _uuid = uuid ?? const Uuid();

  final TaskRepositoryInterface _repo;
  final SyncService _syncService;
  final String _deviceId;
  final Uuid _uuid;

  Future<void> call(
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
  }) async {
    final now = DateTime.now();
    final updated = TaskEntity(
      id: task.id,
      title: (title ?? task.title).trim(),
      description: description != null
          ? (description.trim().isEmpty ? null : description.trim())
          : task.description,
      categoryId: categoryId ?? task.categoryId,
      subcategoryId: subcategoryId ?? task.subcategoryId,
      dueDate: dueDate ?? task.dueDate,
      startDate: startDate ?? task.startDate,
      priority: priority?.index ?? task.priority,
      difficulty: difficulty?.index ?? task.difficulty,
      status: task.status,
      createdAt: task.createdAt,
      updatedAt: now,
      completedAt: task.completedAt,
      recurringRule:
          (recurrence ?? TaskRecurrenceRule.values[task.recurringRule]).index,
      attachments: task.attachments,
      isDirty: true,
      lastSyncedAt: task.lastSyncedAt,
      syncStatus: SyncStatus.idle.index,
      lastModifiedByDevice: _deviceId,
    );
    await _repo.upsert(updated);
    await _enqueueUpsert(updated);
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
