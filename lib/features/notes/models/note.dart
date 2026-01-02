import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/features/notes/models/note_attachment.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';

@HiveType(typeId: HiveTypeIds.note)
class Note extends HiveObject {
  Note({
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
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  String? title;

  /// Quill Delta JSON as a String.
  @HiveField(2)
  String contentDeltaJson;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  String lastModifiedByDevice;

  @HiveField(6)
  List<NoteAttachment> attachments;

  @HiveField(7)
  bool isDirty;

  @HiveField(8)
  DateTime? lastSyncedAt;

  /// SyncStatus index (reuse enum from tasks).
  @HiveField(9)
  int syncStatus;

  @HiveField(10)
  String? categoryId;

  SyncStatus get syncStatusEnum => SyncStatus.values[syncStatus];
  set syncStatusEnum(SyncStatus v) => syncStatus = v.index;

  Map<String, dynamic> toFirestoreJson() => {
    'id': id,
    'title': title,
    'contentDeltaJson': contentDeltaJson,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'lastModifiedByDevice': lastModifiedByDevice,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'categoryId': categoryId,
  };

  static Note fromFirestoreJson(Map<String, dynamic> json) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return Note(
      id: json['id'] as String,
      title: json['title'] as String?,
      contentDeltaJson: (json['contentDeltaJson'] as String?) ?? '[]',
      createdAt: ts(json['createdAt']) ?? DateTime.now(),
      updatedAt: ts(json['updatedAt']) ?? DateTime.now(),
      lastModifiedByDevice:
          (json['lastModifiedByDevice'] as String?) ?? 'unknown',
      attachments: ((json['attachments'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => NoteAttachment.fromJson(e.cast<String, dynamic>()))
          .toList(),
      isDirty: false,
      lastSyncedAt: DateTime.now(),
      syncStatus: SyncStatus.synced.index,
      categoryId: json['categoryId'] as String?,
    );
  }
}

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = HiveTypeIds.note;

  @override
  Note read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return Note(
      id: fields[0] as String,
      title: fields[1] as String?,
      contentDeltaJson: fields[2] as String,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      lastModifiedByDevice: fields[5] as String,
      attachments:
          (fields[6] as List?)?.cast<NoteAttachment>() ?? <NoteAttachment>[],
      isDirty: (fields[7] as bool?) ?? true,
      lastSyncedAt: fields[8] as DateTime?,
      syncStatus: (fields[9] as int?) ?? 0,
      categoryId: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.contentDeltaJson)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.lastModifiedByDevice)
      ..writeByte(6)
      ..write(obj.attachments)
      ..writeByte(7)
      ..write(obj.isDirty)
      ..writeByte(8)
      ..write(obj.lastSyncedAt)
      ..writeByte(9)
      ..write(obj.syncStatus)
      ..writeByte(10)
      ..write(obj.categoryId);
  }
}
