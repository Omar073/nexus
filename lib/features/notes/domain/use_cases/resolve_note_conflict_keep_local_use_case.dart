import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/models/sync_conflict.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/notes/data/models/note.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:uuid/uuid.dart';

/// Resolves a note conflict by preserving the local snapshot.
class ResolveNoteConflictKeepLocalUseCase {
  ResolveNoteConflictKeepLocalUseCase(this._syncService, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final SyncService _syncService;
  final Uuid _uuid;

  Future<void> call(SyncConflict<Note> conflict) async {
    final local = conflict.local;
    local.isDirty = true;
    local.syncStatusEnum = SyncStatus.idle;
    await local.save();

    final op = SyncOperation(
      id: _uuid.v4(),
      type: SyncOperationType.update.index,
      entityType: 'note',
      entityId: local.id,
      createdAt: DateTime.now(),
      data: local.toFirestoreJson(),
    );
    await _syncService.enqueueOperation(op);
    await _syncService.syncOnce();
  }
}
