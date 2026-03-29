import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/utils/conflict_detectable.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';

/// Hive model: title, schedule, completion, snooze, sync fields.

@HiveType(typeId: HiveTypeIds.reminder)
class Reminder extends HiveObject implements ConflictDetectable {
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
    this.isDirty = true,
    this.lastSyncedAt,
    this.syncStatus = 0,
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

  @override
  @HiveField(8)
  DateTime updatedAt;

  /// Whether this reminder has unsynced local changes.
  @override
  @HiveField(9)
  bool isDirty;

  /// Last successful sync timestamp.
  @override
  @HiveField(10)
  DateTime? lastSyncedAt;

  /// SyncStatus index.
  @HiveField(11)
  int syncStatus;

  SyncStatus get syncStatusEnum => SyncStatus.values[syncStatus];
  set syncStatusEnum(SyncStatus v) => syncStatus = v.index;

  /// Firestore payload for this reminder.
  Map<String, dynamic> toFirestoreJson() => {
    'id': id,
    'notificationId': notificationId,
    'title': title,
    'time': Timestamp.fromDate(time),
    'snoozeMinutes': snoozeMinutes,
    'taskId': taskId,
    'completedAt': completedAt == null
        ? null
        : Timestamp.fromDate(completedAt!),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  /// Constructs a Reminder from Firestore data.
  static Reminder fromFirestoreJson(Map<String, dynamic> json) {
    DateTime? ts(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      return null;
    }

    final created = ts(json['createdAt']) ?? DateTime.now();
    final updated = ts(json['updatedAt']) ?? created;

    return Reminder(
      id: json['id'] as String,
      notificationId: (json['notificationId'] as int?) ?? 0,
      title: (json['title'] as String?) ?? '',
      time: ts(json['time']) ?? updated,
      snoozeMinutes: json['snoozeMinutes'] as int?,
      taskId: json['taskId'] as String?,
      completedAt: ts(json['completedAt']),
      createdAt: created,
      updatedAt: updated,
      isDirty: false,
      lastSyncedAt: DateTime.now(),
      syncStatus: SyncStatus.synced.index,
    );
  }
}

/// Serializes [Reminder] for Hive.

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
      isDirty: (fields[9] as bool?) ?? true,
      lastSyncedAt: fields[10] as DateTime?,
      syncStatus: (fields[11] as int?) ?? SyncStatus.idle.index,
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.isDirty)
      ..writeByte(10)
      ..write(obj.lastSyncedAt)
      ..writeByte(11)
      ..write(obj.syncStatus);
  }
}
