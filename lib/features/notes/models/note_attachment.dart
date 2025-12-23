import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive_type_ids.dart';

@HiveType(typeId: HiveTypeIds.noteAttachment)
class NoteAttachment extends HiveObject {
  NoteAttachment({
    required this.id,
    required this.mimeType,
    required this.createdAt,
    this.localUri,
    this.driveFileId,
    this.uploaded = false,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String mimeType;

  @HiveField(2)
  String? localUri;

  @HiveField(3)
  String? driveFileId;

  @HiveField(4)
  bool uploaded;

  @HiveField(5)
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mimeType': mimeType,
        'localUri': localUri,
        'driveFileId': driveFileId,
        'uploaded': uploaded,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  static NoteAttachment fromJson(Map<String, dynamic> json) {
    return NoteAttachment(
      id: json['id'] as String,
      mimeType: (json['mimeType'] as String?) ?? 'application/octet-stream',
      localUri: json['localUri'] as String?,
      driveFileId: json['driveFileId'] as String?,
      uploaded: (json['uploaded'] as bool?) ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

class NoteAttachmentAdapter extends TypeAdapter<NoteAttachment> {
  @override
  final int typeId = HiveTypeIds.noteAttachment;

  @override
  NoteAttachment read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return NoteAttachment(
      id: fields[0] as String,
      mimeType: fields[1] as String,
      localUri: fields[2] as String?,
      driveFileId: fields[3] as String?,
      uploaded: (fields[4] as bool?) ?? false,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NoteAttachment obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mimeType)
      ..writeByte(2)
      ..write(obj.localUri)
      ..writeByte(3)
      ..write(obj.driveFileId)
      ..writeByte(4)
      ..write(obj.uploaded)
      ..writeByte(5)
      ..write(obj.createdAt);
  }
}


