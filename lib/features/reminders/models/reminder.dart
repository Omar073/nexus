import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive_type_ids.dart';

@HiveType(typeId: HiveTypeIds.reminder)
class Reminder extends HiveObject {
  Reminder({
    required this.id,
    required this.notificationId,
    required this.title,
    required this.time,
    required this.createdAt,
    required this.updatedAt,
    this.snoozeMinutes,
    this.taskId,
    this.completedAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final int notificationId;

  @HiveField(2)
  String title;

  @HiveField(3)
  DateTime time;

  @HiveField(4)
  int? snoozeMinutes;

  @HiveField(5)
  String? taskId;

  @HiveField(6)
  DateTime? completedAt;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;
}

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = HiveTypeIds.reminder;

  @override
  Reminder read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return Reminder(
      id: fields[0] as String,
      notificationId: fields[1] as int,
      title: fields[2] as String,
      time: fields[3] as DateTime,
      snoozeMinutes: fields[4] as int?,
      taskId: fields[5] as String?,
      completedAt: fields[6] as DateTime?,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.notificationId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.time)
      ..writeByte(4)
      ..write(obj.snoozeMinutes)
      ..writeByte(5)
      ..write(obj.taskId)
      ..writeByte(6)
      ..write(obj.completedAt)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }
}


