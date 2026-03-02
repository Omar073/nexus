import 'package:nexus/features/notes/domain/entities/note_attachment_entity.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/data/models/note.dart';
import 'package:nexus/features/notes/data/models/note_attachment.dart';

class NoteMapper {
  static NoteEntity toEntity(Note n) {
    return NoteEntity(
      id: n.id,
      title: n.title,
      contentDeltaJson: n.contentDeltaJson,
      createdAt: n.createdAt,
      updatedAt: n.updatedAt,
      lastModifiedByDevice: n.lastModifiedByDevice,
      attachments: n.attachments.map(_attachmentToEntity).toList(),
      isDirty: n.isDirty,
      lastSyncedAt: n.lastSyncedAt,
      syncStatus: n.syncStatus,
      categoryId: n.categoryId,
      isMarkdown: n.isMarkdown,
    );
  }

  static NoteAttachmentEntity _attachmentToEntity(NoteAttachment a) {
    return NoteAttachmentEntity(
      id: a.id,
      mimeType: a.mimeType,
      localUri: a.localUri,
      driveFileId: a.driveFileId,
      uploaded: a.uploaded,
      createdAt: a.createdAt,
    );
  }

  static Note toModel(NoteEntity e) {
    return Note(
      id: e.id,
      title: e.title,
      contentDeltaJson: e.contentDeltaJson,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      lastModifiedByDevice: e.lastModifiedByDevice,
      attachments: e.attachments.map(_attachmentToModel).toList(),
      isDirty: e.isDirty,
      lastSyncedAt: e.lastSyncedAt,
      syncStatus: e.syncStatus,
      categoryId: e.categoryId,
      isMarkdown: e.isMarkdown,
    );
  }

  static NoteAttachment _attachmentToModel(NoteAttachmentEntity a) {
    return NoteAttachment(
      id: a.id,
      mimeType: a.mimeType,
      localUri: a.localUri,
      driveFileId: a.driveFileId,
      uploaded: a.uploaded,
      createdAt: a.createdAt,
    );
  }
}
