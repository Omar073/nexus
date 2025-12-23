import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive_type_ids.dart';

@HiveType(typeId: HiveTypeIds.taskAttachment)
class TaskAttachment extends HiveObject {
  TaskAttachment({
    required this.id,
    required this.mimeType,
    required this.createdAt,
    this.storagePath,
    this.localUri,
    this.uploaded = false,
    this.driveFileId,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  String? storagePath;

  @HiveField(2)
  final String mimeType;

  @HiveField(3)
  String? localUri;

  @HiveField(4)
  bool uploaded;

  @HiveField(5)
  String? driveFileId;

  @HiveField(6)
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'storagePath': storagePath,
        'mimeType': mimeType,
        'localUri': localUri,
        'uploaded': uploaded,
        'driveFileId': driveFileId,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  static TaskAttachment fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      id: json['id'] as String,
      storagePath: json['storagePath'] as String?,
      mimeType: (json['mimeType'] as String?) ?? 'application/octet-stream',
      localUri: json['localUri'] as String?,
      uploaded: (json['uploaded'] as bool?) ?? false,
      driveFileId: json['driveFileId'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

class TaskAttachmentAdapter extends TypeAdapter<TaskAttachment> {
  @override
  final int typeId = HiveTypeIds.taskAttachment;

  @override
  TaskAttachment read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return TaskAttachment(
      id: fields[0] as String,
      storagePath: fields[1] as String?,
      mimeType: fields[2] as String,
      localUri: fields[3] as String?,
      uploaded: (fields[4] as bool?) ?? false,
      driveFileId: fields[5] as String?,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TaskAttachment obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.storagePath)
      ..writeByte(2)
      ..write(obj.mimeType)
      ..writeByte(3)
      ..write(obj.localUri)
      ..writeByte(4)
      ..write(obj.uploaded)
      ..writeByte(5)
      ..write(obj.driveFileId)
      ..writeByte(6)
      ..write(obj.createdAt);
  }
}


