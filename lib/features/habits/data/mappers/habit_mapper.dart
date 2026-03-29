import 'package:nexus/features/habits/domain/entities/habit_entity.dart';
import 'package:nexus/features/habits/data/models/habit.dart';

/// Maps [Habit] Hive model to domain entity and back.

class HabitMapper {
  static HabitEntity toEntity(Habit h) {
    return HabitEntity(
      id: h.id,
      name: h.title,
      createdAt: h.createdAt,
      updatedAt: h.updatedAt,
      colorHex: null,
      iconCodePoint: null,
      linkedRecurringTaskId: h.linkedRecurringTaskId,
      active: h.active,
      isDirty: h.isDirty,
      lastSyncedAt: h.lastSyncedAt,
      syncStatus: h.syncStatus,
    );
  }

  static Habit toModel(HabitEntity e) {
    return Habit(
      id: e.id,
      title: e.name,
      linkedRecurringTaskId: e.linkedRecurringTaskId,
      active: e.active,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      isDirty: e.isDirty,
      lastSyncedAt: e.lastSyncedAt,
      syncStatus: e.syncStatus,
    );
  }
}
