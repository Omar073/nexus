import 'dart:async';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/domain/repositories/note_repository_interface.dart';
import 'package:uuid/uuid.dart';

class SaveNoteUseCase {
  SaveNoteUseCase(
    this._repo,
    this._syncService, {
    required String deviceId,
    Uuid? uuid,
  }) : _deviceId = deviceId,
       _uuid = uuid ?? const Uuid();

  final NoteRepositoryInterface _repo;
  final SyncService _syncService;
  final String _deviceId;
  final Uuid _uuid;

  Future<void> call({
    required String noteId,
    String? title,
    required String contentDeltaJson,
    bool isMarkdown = false,
  }) async {
    final existing = _repo.getById(noteId);
    if (existing == null) return;
    final updated = NoteEntity(
      id: existing.id,
      title: (title?.trim().isEmpty ?? true) ? null : title?.trim(),
      contentDeltaJson: contentDeltaJson,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      lastModifiedByDevice: _deviceId,
      attachments: existing.attachments,
      isDirty: true,
      lastSyncedAt: existing.lastSyncedAt,
      syncStatus: 0,
      categoryId: existing.categoryId,
      isMarkdown: isMarkdown,
    );
    await _repo.upsert(updated);
    await _enqueueUpsert(updated);
  }

  Future<void> _enqueueUpsert(NoteEntity note) async {
    final payload = _repo.getSyncPayload(note.id);
    if (payload == null) return;
    final op = SyncOperation(
      id: _uuid.v4(),
      type: SyncOperationType.update.index,
      entityType: 'note',
      entityId: note.id,
      createdAt: DateTime.now(),
      data: payload,
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }
}
