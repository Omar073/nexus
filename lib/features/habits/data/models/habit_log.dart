import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';

/// Hive model: one habit completion entry for a given day.

@HiveType(typeId: HiveTypeIds.habitLog)
class HabitLog extends HiveObject {
  HabitLog({
    required this.id,
    required this.habitId,
    required this.dayKey,
    required this.completed,
    required this.createdAt,
  });

  /// Unique id for the log row.
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String habitId;

  /// YYYY-MM-DD in local time.
  @HiveField(2)
  final String dayKey;

  @HiveField(3)
  bool completed;

  @HiveField(4)
  final DateTime createdAt;
}

/// Serializes [HabitLog] for Hive.

class HabitLogAdapter extends TypeAdapter<HabitLog> {
  @override
  final int typeId = HiveTypeIds.habitLog;

  @override
  HabitLog read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return HabitLog(
      id: fields[0] as String,
      habitId: fields[1] as String,
      dayKey: fields[2] as String,
      completed: fields[3] as bool,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HabitLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.habitId)
      ..writeByte(2)
      ..write(obj.dayKey)
      ..writeByte(3)
      ..write(obj.completed)
      ..writeByte(4)
      ..write(obj.createdAt);
  }
}
