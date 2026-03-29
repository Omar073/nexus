import 'dart:async';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/habits/domain/entities/habit_entity.dart';
import 'package:nexus/features/habits/domain/entities/habit_log_entity.dart';
import 'package:nexus/features/habits/domain/repositories/habit_log_repository_interface.dart';
import 'package:nexus/features/habits/domain/repositories/habit_repository_interface.dart';
import 'package:uuid/uuid.dart';

/// Marks today complete/incomplete for a habit.

class ToggleHabitTodayUseCase {
  ToggleHabitTodayUseCase(
    this._habits,
    this._logs,
    this._syncService, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final HabitRepositoryInterface _habits;
  final HabitLogRepositoryInterface _logs;
  final SyncService _syncService;
  final Uuid _uuid;

  static String dayKey(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  Future<void> call(HabitEntity habit) async {
    final now = DateTime.now();
    final key = dayKey(now);
    final habitLogs = _logs.getByHabitId(habit.id);
    HabitLogEntity? existing;
    for (final l in habitLogs) {
      if (dayKey(l.date) == key) {
        existing = l;
        break;
      }
    }

    if (existing == null) {
      final newLog = HabitLogEntity(
        id: _uuid.v4(),
        habitId: habit.id,
        date: DateTime(now.year, now.month, now.day),
        createdAt: now,
        completed: true,
      );
      await _logs.upsert(newLog);
    } else {
      final updated = HabitLogEntity(
        id: existing.id,
        habitId: existing.habitId,
        date: existing.date,
        createdAt: existing.createdAt,
        completed: !existing.completed,
      );
      await _logs.upsert(updated);
    }

    final updatedHabit = HabitEntity(
      id: habit.id,
      name: habit.name,
      createdAt: habit.createdAt,
      updatedAt: now,
      colorHex: habit.colorHex,
      iconCodePoint: habit.iconCodePoint,
      linkedRecurringTaskId: habit.linkedRecurringTaskId,
      active: habit.active,
      isDirty: true,
      lastSyncedAt: habit.lastSyncedAt,
      syncStatus: habit.syncStatus,
    );
    await _habits.upsert(updatedHabit);

    final payload = _habits.getSyncPayload(updatedHabit.id);
    if (payload != null) {
      final op = SyncOperation(
        id: _uuid.v4(),
        type: SyncOperationType.update.index,
        entityType: 'habit',
        entityId: updatedHabit.id,
        createdAt: DateTime.now(),
        data: payload,
      );
      await _syncService.enqueueOperation(op);
      unawaited(_syncService.syncOnce());
    }
  }
}
