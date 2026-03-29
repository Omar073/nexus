import 'dart:async';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/repositories/task_repository_interface.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:uuid/uuid.dart';

/// Sets category to null when a category is deleted.

class ClearCategoryOnTasksUseCase {
  ClearCategoryOnTasksUseCase(
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

  Future<void> call(List<String> categoryIds) async {
    final all = _repo.getAll();
    for (final task in all) {
      if (!categoryIds.contains(task.categoryId) &&
          !categoryIds.contains(task.subcategoryId)) {
        continue;
      }
      final clearCategory = categoryIds.contains(task.categoryId);
      final clearSubcategory = categoryIds.contains(task.subcategoryId);
      if (!clearCategory && !clearSubcategory) continue;
      final updated = TaskEntity(
        id: task.id,
        title: task.title,
        description: task.description,
        categoryId: clearCategory ? null : task.categoryId,
        subcategoryId: clearSubcategory ? null : task.subcategoryId,
        dueDate: task.dueDate,
        startDate: task.startDate,
        priority: task.priority,
        difficulty: task.difficulty,
        status: task.status,
        createdAt: task.createdAt,
        updatedAt: DateTime.now(),
        completedAt: task.completedAt,
        recurringRule: task.recurringRule,
        attachments: task.attachments,
        isDirty: true,
        lastSyncedAt: task.lastSyncedAt,
        syncStatus: SyncStatus.idle.index,
        lastModifiedByDevice: _deviceId,
      );
      await _repo.upsert(updated);
      await _enqueueUpsert(updated);
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
