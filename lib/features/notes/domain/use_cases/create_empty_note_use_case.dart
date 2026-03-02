import 'dart:async';
import 'dart:convert';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/domain/repositories/note_repository_interface.dart';
import 'package:uuid/uuid.dart';

class CreateEmptyNoteUseCase {
  CreateEmptyNoteUseCase(
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

  Future<NoteEntity> call({String? categoryId}) async {
    final now = DateTime.now();
    final entity = NoteEntity(
      id: _uuid.v4(),
      title: null,
      contentDeltaJson: jsonEncode([
        {'insert': '\n'},
      ]),
      createdAt: now,
      updatedAt: now,
      lastModifiedByDevice: _deviceId,
      attachments: const [],
      isDirty: true,
      syncStatus: 0,
      categoryId: categoryId,
    );
    await _repo.upsert(entity);
    await _enqueueUpsert(entity, isCreate: true);
    return entity;
  }

  Future<void> _enqueueUpsert(NoteEntity note, {required bool isCreate}) async {
    final payload = _repo.getSyncPayload(note.id);
    if (payload == null) return;
    final op = SyncOperation(
      id: _uuid.v4(),
      type: (isCreate ? SyncOperationType.create : SyncOperationType.update)
          .index,
      entityType: 'note',
      entityId: note.id,
      createdAt: DateTime.now(),
      data: payload,
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }
}
