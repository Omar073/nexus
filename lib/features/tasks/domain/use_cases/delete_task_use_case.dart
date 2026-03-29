import 'dart:async';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/repositories/task_repository_interface.dart';
import 'package:uuid/uuid.dart';

/// Removes a task and enqueues remote delete.

class DeleteTaskUseCase {
  DeleteTaskUseCase(this._repo, this._syncService, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final TaskRepositoryInterface _repo;
  final SyncService _syncService;
  final Uuid _uuid;

  Future<void> call(TaskEntity task) async {
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
}
