import 'package:flutter/foundation.dart';
import 'package:nexus/features/habits/models/habit.dart';
import 'package:nexus/features/habits/models/habit_log.dart';
import 'package:nexus/features/habits/models/habit_log_repository.dart';
import 'package:nexus/features/habits/models/habit_repository.dart';
import 'package:uuid/uuid.dart';

class HabitController extends ChangeNotifier {
  HabitController({
    required HabitRepository habits,
    required HabitLogRepository logs,
  }) : _habits = habits,
       _logs = logs,
       _habitsListenable = habits.listenable(),
       _logsListenable = logs.listenable() {
    _habitsListenable.addListener(notifyListeners);
    _logsListenable.addListener(notifyListeners);
  }

  final HabitRepository _habits;
  final HabitLogRepository _logs;
  final Listenable _habitsListenable;
  final Listenable _logsListenable;

  static const _uuid = Uuid();

  @override
  void dispose() {
    _habitsListenable.removeListener(notifyListeners);
    _logsListenable.removeListener(notifyListeners);
    super.dispose();
  }

  List<Habit> get habits {
    final all = _habits.getAll().toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  List<HabitLog> get logs => _logs.getAll();

  static String dayKey(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  bool isCompletedToday(String habitId) {
    final key = dayKey(DateTime.now());
    return logs.any(
      (l) => l.habitId == habitId && l.dayKey == key && l.completed,
    );
  }

  int currentStreak(String habitId) {
    final completedDays = logs
        .where((l) => l.habitId == habitId && l.completed)
        .map((l) => l.dayKey)
        .toSet();
    var streak = 0;
    var cursor = DateTime.now();
    while (true) {
      final key = dayKey(cursor);
      if (!completedDays.contains(key)) break;
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<Habit> createHabit({
    required String title,
    String? linkedRecurringTaskId,
  }) async {
    final now = DateTime.now();
    final habit = Habit(
      id: _uuid.v4(),
      title: title.trim(),
      linkedRecurringTaskId: linkedRecurringTaskId,
      active: true,
      createdAt: now,
      updatedAt: now,
    );
    await _habits.upsert(habit);
    return habit;
  }

  Future<void> toggleToday(Habit habit) async {
    final key = dayKey(DateTime.now());
    final existing = logs.firstWhere(
      (l) => l.habitId == habit.id && l.dayKey == key,
      orElse: () => HabitLog(
        id: _uuid.v4(),
        habitId: habit.id,
        dayKey: key,
        completed: false,
        createdAt: DateTime.now(),
      ),
    );

    existing.completed = !existing.completed;
    await _logs.upsert(existing);

    habit.updatedAt = DateTime.now();
    await habit.save();
  }
}
