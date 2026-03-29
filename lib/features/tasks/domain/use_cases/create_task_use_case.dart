import 'dart:async';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/repositories/task_repository_interface.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:uuid/uuid.dart';

/// Creates a task with defaults and stores locally.

class CreateTaskUseCase {
  CreateTaskUseCase(
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

  Future<TaskEntity> call({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskDifficulty? difficulty,
    TaskRecurrenceRule recurrence = TaskRecurrenceRule.none,
    String? categoryId,
    String? subcategoryId,
  }) async {
    final now = DateTime.now();
    final entity = TaskEntity(
      id: _uuid.v4(),
      title: title.trim(),
      description: (description?.trim().isEmpty ?? true)
          ? null
          : description?.trim(),
      status: TaskStatus.active.index,
      createdAt: now,
      updatedAt: now,
      dueDate: dueDate,
      startDate: startDate,
      priority: priority?.index,
      difficulty: difficulty?.index,
      recurringRule: recurrence.index,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      lastModifiedByDevice: _deviceId,
      isDirty: true,
      syncStatus: SyncStatus.idle.index,
    );
    await _repo.upsert(entity);
    await _enqueueUpsert(entity, isCreate: true);
    return entity;
  }

  Future<void> _enqueueUpsert(TaskEntity task, {required bool isCreate}) async {
    final payload = _repo.getSyncPayload(task.id);
    if (payload == null) return;
    final op = SyncOperation(
      id: _uuid.v4(),
      type: (isCreate ? SyncOperationType.create : SyncOperationType.update)
          .index,
      entityType: 'task',
      entityId: task.id,
      createdAt: DateTime.now(),
      data: payload,
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }
}
