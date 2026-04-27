import 'dart:async';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/domain/repositories/note_repository_interface.dart';
import 'package:uuid/uuid.dart';

/// Restores a deleted note and re-enqueues a create sync operation.
class RestoreNoteUseCase {
  RestoreNoteUseCase(this._repo, this._syncService, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final NoteRepositoryInterface _repo;
  final SyncService _syncService;
  final Uuid _uuid;

  Future<void> call(NoteEntity note) async {
    await _repo.upsert(note);
    final payload = _repo.getSyncPayload(note.id);
    if (payload == null) return;
    final op = SyncOperation(
      id: _uuid.v4(),
      type: SyncOperationType.create.index,
      entityType: 'note',
      entityId: note.id,
      createdAt: DateTime.now(),
      data: payload,
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }
}
