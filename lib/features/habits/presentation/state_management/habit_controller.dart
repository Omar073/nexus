import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/habits/domain/entities/habit_entity.dart';
import 'package:nexus/features/habits/domain/entities/habit_log_entity.dart';
import 'package:nexus/features/habits/domain/repositories/habit_log_repository_interface.dart';
import 'package:nexus/features/habits/domain/repositories/habit_repository_interface.dart';
import 'package:nexus/features/habits/domain/use_cases/create_habit_use_case.dart';
import 'package:nexus/features/habits/domain/use_cases/toggle_habit_today_use_case.dart';

class HabitController extends ChangeNotifier {
  HabitController({
    required HabitRepositoryInterface habits,
    required HabitLogRepositoryInterface logs,
    required SyncService syncService,
  }) : _habits = habits,
       _logs = logs,
       _create = CreateHabitUseCase(habits, syncService),
       _toggleToday = ToggleHabitTodayUseCase(habits, logs, syncService) {
    _habitSub = habits.changes.listen((_) => notifyListeners());
    _logSub = logs.changes.listen((_) => notifyListeners());
  }

  final HabitRepositoryInterface _habits;
  final HabitLogRepositoryInterface _logs;
  final CreateHabitUseCase _create;
  final ToggleHabitTodayUseCase _toggleToday;
  StreamSubscription<void>? _habitSub;
  StreamSubscription<void>? _logSub;

  @override
  void dispose() {
    _habitSub?.cancel();
    _logSub?.cancel();
    super.dispose();
  }

  List<HabitEntity> get habits {
    final all = _habits.getAll().toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  List<HabitLogEntity> get logs => _logs.getAll();

  static String dayKey(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  bool isCompletedToday(String habitId) {
    final key = dayKey(DateTime.now());
    return logs.any(
      (l) => l.habitId == habitId && dayKey(l.date) == key && l.completed,
    );
  }

  int currentStreak(String habitId) {
    final completedDays = logs
        .where((l) => l.habitId == habitId && l.completed)
        .map((l) => dayKey(l.date))
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

  Future<HabitEntity> createHabit({
    required String title,
    String? linkedRecurringTaskId,
  }) =>
      _create.call(title: title, linkedRecurringTaskId: linkedRecurringTaskId);

  Future<void> toggleToday(HabitEntity habit) => _toggleToday.call(habit);
}
