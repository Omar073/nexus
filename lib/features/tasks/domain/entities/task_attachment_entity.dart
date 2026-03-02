/// Domain entity for a task attachment (pure Dart, no Hive).
class TaskAttachmentEntity {
  const TaskAttachmentEntity({
    required this.id,
    required this.mimeType,
    required this.createdAt,
    this.storagePath,
    this.localUri,
    this.driveFileId,
    this.uploaded = false,
  });

  final String id;
  final String? storagePath;
  final String mimeType;
  final String? localUri;
  final String? driveFileId;
  final bool uploaded;
  final DateTime createdAt;
}
