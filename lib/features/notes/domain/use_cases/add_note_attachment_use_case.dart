import 'dart:async';
import 'dart:io';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/notes/domain/entities/note_attachment_entity.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/domain/repositories/note_repository_interface.dart';
import 'package:uuid/uuid.dart';

class AddNoteAttachmentUseCase {
  AddNoteAttachmentUseCase(
    this._repo,
    this._syncService,
    this._googleDrive, {
    required String deviceId,
    Uuid? uuid,
  }) : _deviceId = deviceId,
       _uuid = uuid ?? const Uuid();

  final NoteRepositoryInterface _repo;
  final SyncService _syncService;
  final GoogleDriveService _googleDrive;
  final String _deviceId;
  final Uuid _uuid;

  Future<void> call(NoteEntity note, NoteAttachmentEntity attachment) async {
    var attachmentList = [...note.attachments, attachment];
    var updated = NoteEntity(
      id: note.id,
      title: note.title,
      contentDeltaJson: note.contentDeltaJson,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
      lastModifiedByDevice: _deviceId,
      attachments: attachmentList,
      isDirty: true,
      lastSyncedAt: note.lastSyncedAt,
      syncStatus: 0,
      categoryId: note.categoryId,
      isMarkdown: note.isMarkdown,
    );
    await _repo.upsert(updated);

    if (attachment.localUri != null && attachment.localUri!.isNotEmpty) {
      try {
        final file = File(attachment.localUri!);
        if (await file.exists()) {
          final driveId = await _googleDrive.uploadNoteFile(
            noteId: note.id,
            file: file,
            filename: attachment.id,
            mimeType: attachment.mimeType,
          );
          final uploadedAtt = NoteAttachmentEntity(
            id: attachment.id,
            mimeType: attachment.mimeType,
            localUri: attachment.localUri,
            driveFileId: driveId,
            uploaded: true,
            createdAt: attachment.createdAt,
          );
          attachmentList = [...note.attachments, uploadedAtt];
          updated = NoteEntity(
            id: note.id,
            title: note.title,
            contentDeltaJson: note.contentDeltaJson,
            createdAt: note.createdAt,
            updatedAt: DateTime.now(),
            lastModifiedByDevice: _deviceId,
            attachments: attachmentList,
            isDirty: true,
            lastSyncedAt: note.lastSyncedAt,
            syncStatus: 0,
            categoryId: note.categoryId,
            isMarkdown: note.isMarkdown,
          );
          await _repo.upsert(updated);
        }
      } catch (e) {
        rethrow;
      }
    }

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
