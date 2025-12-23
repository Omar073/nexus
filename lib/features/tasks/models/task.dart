import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive_type_ids.dart';
import 'package:nexus/features/tasks/models/task_attachment.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';

@HiveType(typeId: HiveTypeIds.task)
class Task extends HiveObject {
  Task({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.lastModifiedByDevice,
    this.description,
    this.categoryId,
    this.subcategoryId,
    this.dueDate,
    this.priority,
    this.difficulty,
    this.completedAt,
    this.recurringRule = 0,
    this.attachments = const [],
    this.isDirty = true,
    this.lastSyncedAt,
    this.syncStatus = 0,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String? categoryId;

  @HiveField(4)
  String? subcategoryId;

  @HiveField(5)
  DateTime? dueDate;

  /// TaskPriority index (nullable).
  @HiveField(6)
  int? priority;

  /// TaskDifficulty index (nullable).
  @HiveField(7)
  int? difficulty;

  /// TaskStatus index.
  @HiveField(8)
  int status;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  @HiveField(11)
  DateTime? completedAt;

  /// TaskRecurrenceRule index.
  @HiveField(12)
  int recurringRule;

  @HiveField(13)
  List<TaskAttachment> attachments;

  @HiveField(14)
  bool isDirty;

  @HiveField(15)
  DateTime? lastSyncedAt;

  /// SyncStatus index.
  @HiveField(16)
  int syncStatus;

  @HiveField(17)
  String lastModifiedByDevice;

  TaskStatus get statusEnum => TaskStatus.values[status];
  set statusEnum(TaskStatus v) => status = v.index;

  TaskPriority? get priorityEnum =>
      priority == null ? null : TaskPriority.values[priority!];
  set priorityEnum(TaskPriority? v) => priority = v?.index;

  TaskDifficulty? get difficultyEnum =>
      difficulty == null ? null : TaskDifficulty.values[difficulty!];
  set difficultyEnum(TaskDifficulty? v) => difficulty = v?.index;

  TaskRecurrenceRule get recurringRuleEnum =>
      TaskRecurrenceRule.values[recurringRule];
  set recurringRuleEnum(TaskRecurrenceRule v) => recurringRule = v.index;

  SyncStatus get syncStatusEnum => SyncStatus.values[syncStatus];
  set syncStatusEnum(SyncStatus v) => syncStatus = v.index;

  Map<String, dynamic> toFirestoreJson() => {
        'id': id,
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,
        'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
        'priority': priority,
        'difficulty': difficulty,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'completedAt': completedAt == null ? null : Timestamp.fromDate(completedAt!),
        'recurringRule': recurringRule,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'lastModifiedByDevice': lastModifiedByDevice,
      };

  static Task fromFirestoreJson(Map<String, dynamic> json) {
    DateTime? ts(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return Task(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      categoryId: json['categoryId'] as String?,
      subcategoryId: json['subcategoryId'] as String?,
      dueDate: ts(json['dueDate']),
      priority: json['priority'] as int?,
      difficulty: json['difficulty'] as int?,
      status: (json['status'] as int?) ?? TaskStatus.active.index,
      createdAt: ts(json['createdAt']) ?? DateTime.now(),
      updatedAt: ts(json['updatedAt']) ?? DateTime.now(),
      completedAt: ts(json['completedAt']),
      recurringRule: (json['recurringRule'] as int?) ?? TaskRecurrenceRule.none.index,
      attachments: ((json['attachments'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => TaskAttachment.fromJson(e.cast<String, dynamic>()))
          .toList(),
      lastModifiedByDevice: (json['lastModifiedByDevice'] as String?) ?? 'unknown',
      isDirty: false,
      lastSyncedAt: DateTime.now(),
      syncStatus: SyncStatus.synced.index,
    );
  }
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = HiveTypeIds.task;

  @override
  Task read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      categoryId: fields[3] as String?,
      subcategoryId: fields[4] as String?,
      dueDate: fields[5] as DateTime?,
      priority: fields[6] as int?,
      difficulty: fields[7] as int?,
      status: fields[8] as int,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      completedAt: fields[11] as DateTime?,
      recurringRule: (fields[12] as int?) ?? TaskRecurrenceRule.none.index,
      attachments: (fields[13] as List?)?.cast<TaskAttachment>() ?? <TaskAttachment>[],
      isDirty: (fields[14] as bool?) ?? true,
      lastSyncedAt: fields[15] as DateTime?,
      syncStatus: (fields[16] as int?) ?? SyncStatus.idle.index,
      lastModifiedByDevice: (fields[17] as String?) ?? 'unknown',
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.subcategoryId)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.priority)
      ..writeByte(7)
      ..write(obj.difficulty)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.completedAt)
      ..writeByte(12)
      ..write(obj.recurringRule)
      ..writeByte(13)
      ..write(obj.attachments)
      ..writeByte(14)
      ..write(obj.isDirty)
      ..writeByte(15)
      ..write(obj.lastSyncedAt)
      ..writeByte(16)
      ..write(obj.syncStatus)
      ..writeByte(17)
      ..write(obj.lastModifiedByDevice);
  }
}


