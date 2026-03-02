import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/utils/conflict_detectable.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';

@HiveType(typeId: HiveTypeIds.habit)
class Habit extends HiveObject implements ConflictDetectable {
  Habit({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.linkedRecurringTaskId,
    this.active = true,
    this.isDirty = true,
    this.lastSyncedAt,
    this.syncStatus = 0,
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
  @override
  DateTime updatedAt;

  /// Whether this habit has unsynced local changes.
  @HiveField(6)
  @override
  bool isDirty;

  /// Last successful sync timestamp.
  @HiveField(7)
  @override
  DateTime? lastSyncedAt;

  /// SyncStatus index.
  @HiveField(8)
  int syncStatus;

  SyncStatus get syncStatusEnum => SyncStatus.values[syncStatus];
  set syncStatusEnum(SyncStatus v) => syncStatus = v.index;

  /// Firestore payload for this habit.
  Map<String, dynamic> toFirestoreJson() => {
    'id': id,
    'title': title,
    'linkedRecurringTaskId': linkedRecurringTaskId,
    'active': active,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  /// Constructs a Habit from Firestore data.
  static Habit fromFirestoreJson(Map<String, dynamic> json) {
    DateTime? ts(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      return null;
    }

    final created = ts(json['createdAt']) ?? DateTime.now();
    final updated = ts(json['updatedAt']) ?? created;

    return Habit(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      linkedRecurringTaskId: json['linkedRecurringTaskId'] as String?,
      active: (json['active'] as bool?) ?? true,
      createdAt: created,
      updatedAt: updated,
      isDirty: false,
      lastSyncedAt: DateTime.now(),
      syncStatus: SyncStatus.synced.index,
    );
  }
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
      isDirty: (fields[6] as bool?) ?? true,
      lastSyncedAt: fields[7] as DateTime?,
      syncStatus: (fields[8] as int?) ?? SyncStatus.idle.index,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.isDirty)
      ..writeByte(7)
      ..write(obj.lastSyncedAt)
      ..writeByte(8)
      ..write(obj.syncStatus);
  }
}
