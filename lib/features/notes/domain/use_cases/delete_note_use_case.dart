import 'dart:async';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/domain/repositories/note_repository_interface.dart';
import 'package:uuid/uuid.dart';

/// Removes a note locally and enqueues remote delete.

class DeleteNoteUseCase {
  DeleteNoteUseCase(this._repo, this._syncService, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final NoteRepositoryInterface _repo;
  final SyncService _syncService;
  final Uuid _uuid;

  Future<void> call(NoteEntity note) async {
    await _repo.delete(note.id);
    final op = SyncOperation(
      id: _uuid.v4(),
      type: SyncOperationType.delete.index,
      entityType: 'note',
      entityId: note.id,
      createdAt: DateTime.now(),
      data: null,
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }
}
