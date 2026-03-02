/// Domain entity for a habit (pure Dart, no Hive).
class HabitEntity {
  const HabitEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.colorHex,
    this.iconCodePoint,
    this.linkedRecurringTaskId,
    this.active = true,
    this.isDirty = true,
    this.lastSyncedAt,
    this.syncStatus = 0,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? colorHex;
  final int? iconCodePoint;
  final String? linkedRecurringTaskId;
  final bool active;
  final bool isDirty;
  final DateTime? lastSyncedAt;
  final int syncStatus;
}
