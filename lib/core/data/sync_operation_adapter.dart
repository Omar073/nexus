import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/data/sync_queue.dart';

/// Custom Hive adapter for [SyncOperation].
///
/// Handles serialization/deserialization of sync operations, including
/// conversion of Firestore Timestamps to DateTime for Hive compatibility.
class SyncOperationAdapter extends TypeAdapter<SyncOperation> {
  @override
  final int typeId = HiveTypeIds.syncOperation;

  @override
  SyncOperation read(BinaryReader reader) {
    // Hive stores objects in a key-value binary format:
    // [fieldCount][key0][value0][key1][value1]...
    //
    // First byte = number of fields stored
    final fieldCount = reader.readByte();

    // Build a map of field index → value
    // This allows us to handle missing fields gracefully (backwards compatibility)
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      // Each field is stored as: [1-byte key (field index)][encoded value]
      final key = reader.readByte(); // e.g., 0 = id, 1 = type, 2 = entityType
      // Hive auto-decodes based on registered adapters
      fields[key] = reader.read();
    }

    return SyncOperation(
      id: fields[0] as String,
      type: fields[1] as int,
      entityType: fields[2] as String,
      entityId: fields[3] as String,
      // JSON snapshot of the entity (e.g., full Task or Note) for retry support.
      data: (fields[4] as Map?)?.cast<String, dynamic>(),
      retryCount: (fields[5] as int?) ?? 0,
      createdAt: (fields[6] as DateTime?) ?? DateTime.now(),
      lastAttemptAt: fields[7] as DateTime?,
      status: (fields[8] as int?) ?? SyncOperationStatus.pending.index,
    );
  }

  /// Recursively converts Firestore Timestamps to DateTime for Hive storage.
  dynamic _convertTimestamps(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is Map) {
      return value
          .map((k, v) => MapEntry(k, _convertTimestamps(v)))
          .cast<String, dynamic>();
    } else if (value is List) {
      return value.map(_convertTimestamps).toList();
    }
    return value;
  }

  @override
  void write(BinaryWriter writer, SyncOperation obj) {
    // Convert Firestore Timestamps → DateTime (Hive can't store Timestamps)
    final sanitizedData = obj.data != null
        ? _convertTimestamps(obj.data) as Map<String, dynamic>?
        : null;

    // Write fields in Hive's binary format: [fieldCount][key][value][key][value]...
    // The cascade operator (..) chains calls on the same writer instance.
    writer
      ..writeByte(9) // Total number of fields we're writing
      // Field 0: id (unique identifier for this sync operation)
      ..writeByte(0)
      ..write(obj.id)
      // Field 1: type (0=create, 1=update, 2=delete)
      ..writeByte(1)
      ..write(obj.type)
      // Field 2: entityType (e.g., 'task', 'note', 'reminder')
      ..writeByte(2)
      ..write(obj.entityType)
      // Field 3: entityId (ID of the entity being synced)
      ..writeByte(3)
      ..write(obj.entityId)
      // Field 4: data (JSON snapshot of the entity for retry support)
      ..writeByte(4)
      ..write(sanitizedData)
      // Field 5: retryCount (how many times sync has failed)
      ..writeByte(5)
      ..write(obj.retryCount)
      // Field 6: createdAt (when the operation was queued)
      ..writeByte(6)
      ..write(obj.createdAt)
      // Field 7: lastAttemptAt (when sync was last attempted)
      ..writeByte(7)
      ..write(obj.lastAttemptAt)
      // Field 8: status (0=pending, 1=syncing, 2=failed, 3=completed)
      ..writeByte(8)
      ..write(obj.status);
  }
}
