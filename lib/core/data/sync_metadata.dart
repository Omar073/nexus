import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';

@HiveType(typeId: HiveTypeIds.syncMetadata)
class SyncMetadata extends HiveObject {
  SyncMetadata({required this.id, this.lastSuccessfulSyncAt});

  @HiveField(0)
  final String id;

  @HiveField(1)
  DateTime? lastSuccessfulSyncAt;
}

class SyncMetadataAdapter extends TypeAdapter<SyncMetadata> {
  @override
  final int typeId = HiveTypeIds.syncMetadata;

  @override
  SyncMetadata read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return SyncMetadata(
      id: fields[0] as String,
      lastSuccessfulSyncAt: fields[1] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncMetadata obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lastSuccessfulSyncAt);
  }
}
