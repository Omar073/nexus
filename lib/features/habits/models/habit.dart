import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive_type_ids.dart';

@HiveType(typeId: HiveTypeIds.habit)
class Habit extends HiveObject {
  Habit({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.linkedRecurringTaskId,
    this.active = true,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? linkedRecurringTaskId;

  @HiveField(3)
  bool active;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;
}

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = HiveTypeIds.habit;

  @override
  Habit read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return Habit(
      id: fields[0] as String,
      title: fields[1] as String,
      linkedRecurringTaskId: fields[2] as String?,
      active: (fields[3] as bool?) ?? true,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.linkedRecurringTaskId)
      ..writeByte(3)
      ..write(obj.active)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }
}


