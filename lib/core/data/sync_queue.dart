import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive_type_ids.dart';

enum SyncOperationType { create, update, delete }

enum SyncOperationStatus { pending, syncing, failed, completed }

@HiveType(typeId: HiveTypeIds.syncOperation)
class SyncOperation extends HiveObject {
  SyncOperation({
    required this.id,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    this.data,
    this.retryCount = 0,
    this.lastAttemptAt,
    this.status = 0,
  });

  @HiveField(0)
  final String id;

  /// create/update/delete
  @HiveField(1)
  final int type;

  /// task/category/reminder
  @HiveField(2)
  final String entityType;

  @HiveField(3)
  final String entityId;

  /// JSON snapshot for retry.
  @HiveField(4)
  final Map<String, dynamic>? data;

  @HiveField(5)
  int retryCount;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  DateTime? lastAttemptAt;

  @HiveField(8)
  int status;
}

class SyncOperationAdapter extends TypeAdapter<SyncOperation> {
  @override
  final int typeId = HiveTypeIds.syncOperation;

  @override
  SyncOperation read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return SyncOperation(
      id: fields[0] as String,
      type: fields[1] as int,
      entityType: fields[2] as String,
      entityId: fields[3] as String,
      data: (fields[4] as Map?)?.cast<String, dynamic>(),
      retryCount: (fields[5] as int?) ?? 0,
      createdAt: fields[6] as DateTime,
      lastAttemptAt: fields[7] as DateTime?,
      status: (fields[8] as int?) ?? SyncOperationStatus.pending.index,
    );
  }

  @override
  void write(BinaryWriter writer, SyncOperation obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.entityType)
      ..writeByte(3)
      ..write(obj.entityId)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.retryCount)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.lastAttemptAt)
      ..writeByte(8)
      ..write(obj.status);
  }
}


