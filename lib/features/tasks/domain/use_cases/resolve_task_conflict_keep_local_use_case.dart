import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/models/sync_conflict.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/tasks/data/models/task.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:uuid/uuid.dart';

/// Resolves a task conflict by preserving the local snapshot.
class ResolveTaskConflictKeepLocalUseCase {
  ResolveTaskConflictKeepLocalUseCase(this._syncService, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final SyncService _syncService;
  final Uuid _uuid;

  Future<void> call(SyncConflict<Task> conflict) async {
    final local = conflict.local;
    local.syncStatusEnum = SyncStatus.idle;
    local.isDirty = true;
    await local.save();

    final op = SyncOperation(
      id: _uuid.v4(),
      type: SyncOperationType.update.index,
      entityType: 'task',
      entityId: local.id,
      createdAt: DateTime.now(),
      data: local.toFirestoreJson(),
    );
    await _syncService.enqueueOperation(op);
    await _syncService.syncOnce();
  }
}
