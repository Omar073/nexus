import 'dart:async';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/storage/attachment_cleanup_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/domain/repositories/note_repository_interface.dart';
import 'package:uuid/uuid.dart';

/// Removes a note attachment and syncs the note update.
class RemoveNoteAttachmentUseCase {
  RemoveNoteAttachmentUseCase(
    this._repo,
    this._syncService,
    this._attachmentCleanup, {
    required String deviceId,
    Uuid? uuid,
  }) : _deviceId = deviceId,
       _uuid = uuid ?? const Uuid();

  final NoteRepositoryInterface _repo;
  final SyncService _syncService;
  final AttachmentCleanupService _attachmentCleanup;
  final String _deviceId;
  final Uuid _uuid;

  Future<void> call({
    required String noteId,
    required String attachmentId,
  }) async {
    final existing = _repo.getById(noteId);
    if (existing == null) return;

    NoteAttachmentTarget? target;
    for (final attachment in existing.attachments) {
      if (attachment.id == attachmentId) {
        target = NoteAttachmentTarget(
          localUri: attachment.localUri,
          driveFileId: attachment.driveFileId,
        );
        break;
      }
    }
    if (target == null) return;

    final updated = NoteEntity(
      id: existing.id,
      title: existing.title,
      contentDeltaJson: existing.contentDeltaJson,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      lastModifiedByDevice: _deviceId,
      attachments: existing.attachments
          .where((a) => a.id != attachmentId)
          .toList(),
      isDirty: true,
      lastSyncedAt: existing.lastSyncedAt,
      syncStatus: 0,
      categoryId: existing.categoryId,
      isMarkdown: existing.isMarkdown,
    );

    await _repo.upsert(updated);
    await _enqueueUpsert(noteId);

    _attachmentCleanup.deleteLocalInBackground(target.localUri);
    await _attachmentCleanup.deleteDriveIfPresent(target.driveFileId);
  }

  Future<void> _enqueueUpsert(String noteId) async {
    final payload = _repo.getSyncPayload(noteId);
    if (payload == null) return;
    final op = SyncOperation(
      id: _uuid.v4(),
      type: SyncOperationType.update.index,
      entityType: 'note',
      entityId: noteId,
      createdAt: DateTime.now(),
      data: payload,
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }
}

class NoteAttachmentTarget {
  NoteAttachmentTarget({required this.localUri, required this.driveFileId});

  final String? localUri;
  final String? driveFileId;
}
