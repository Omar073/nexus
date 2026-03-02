import 'package:nexus/features/notes/domain/entities/note_attachment_entity.dart';

/// Domain entity for a note (pure Dart, no Hive/Flutter).
class NoteEntity {
  const NoteEntity({
    required this.id,
    required this.contentDeltaJson,
    required this.createdAt,
    required this.updatedAt,
    required this.lastModifiedByDevice,
    this.title,
    this.attachments = const [],
    this.isDirty = true,
    this.lastSyncedAt,
    this.syncStatus = 0,
    this.categoryId,
    this.isMarkdown = false,
  });

  final String id;
  final String? title;
  final String contentDeltaJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lastModifiedByDevice;
  final List<NoteAttachmentEntity> attachments;
  final bool isDirty;
  final DateTime? lastSyncedAt;
  final int syncStatus;
  final String? categoryId;
  final bool isMarkdown;
}
