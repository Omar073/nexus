import 'package:intl/intl.dart';
import 'package:nexus/features/habits/domain/entities/habit_log_entity.dart';
import 'package:nexus/features/habits/data/models/habit_log.dart';

/// Maps [HabitLog] Hive model to domain entity and back.

class HabitLogMapper {
  static String _dayKey(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    return DateFormat('yyyy-MM-dd').format(local);
  }

  static DateTime _parseDayKey(String key) {
    return DateFormat('yyyy-MM-dd').parse(key);
  }

  static HabitLogEntity toEntity(HabitLog log) {
    return HabitLogEntity(
      id: log.id,
      habitId: log.habitId,
      date: _parseDayKey(log.dayKey),
      createdAt: log.createdAt,
      completed: log.completed,
    );
  }

  static HabitLog toModel(HabitLogEntity e) {
    return HabitLog(
      id: e.id,
      habitId: e.habitId,
      dayKey: _dayKey(e.date),
      completed: e.completed,
      createdAt: e.createdAt,
    );
  }
}
