/// Domain entity for a note attachment (pure Dart, no Hive).
class NoteAttachmentEntity {
  const NoteAttachmentEntity({
    required this.id,
    required this.mimeType,
    required this.createdAt,
    this.localUri,
    this.driveFileId,
    this.uploaded = false,
  });

  final String id;
  final String mimeType;
  final String? localUri;
  final String? driveFileId;
  final bool uploaded;
  final DateTime createdAt;
}
