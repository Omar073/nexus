import 'package:flutter/foundation.dart';
import 'package:nexus/features/habits/presentation/state_management/habit_controller.dart';
import 'package:nexus/features/reminders/presentation/state_management/reminder_controller.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';

class AnalyticsSnapshot {
  AnalyticsSnapshot({
    required this.activeTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.upcomingReminders,
    required this.totalHabits,
    required this.habitsDoneToday,
  });

  final int activeTasks;
  final int completedTasks;
  final int overdueTasks;
  final int upcomingReminders;
  final int totalHabits;
  final int habitsDoneToday;
}

class AnalyticsController extends ChangeNotifier {
  AnalyticsController({
    required TaskController tasks,
    required ReminderController reminders,
    required HabitController habits,
  }) : _tasks = tasks,
       _reminders = reminders,
       _habits = habits {
    _tasks.addListener(_recompute);
    _reminders.addListener(_recompute);
    _habits.addListener(_recompute);
    _recompute();
  }

  final TaskController _tasks;
  final ReminderController _reminders;
  final HabitController _habits;

  AnalyticsSnapshot _snapshot = AnalyticsSnapshot(
    activeTasks: 0,
    completedTasks: 0,
    overdueTasks: 0,
    upcomingReminders: 0,
    totalHabits: 0,
    habitsDoneToday: 0,
  );

  AnalyticsSnapshot get snapshot => _snapshot;

  void _recompute() {
    final now = DateTime.now();

    final active = _tasks.tasksForStatus(TaskStatus.active).length;
    final completed = _tasks.tasksForStatus(TaskStatus.completed).length;
    final overdue = _tasks
        .tasksForStatus(TaskStatus.active)
        .where((t) => t.dueDate != null && t.dueDate!.isBefore(now))
        .length;

    final upcomingReminders = _reminders.upcoming.length;

    final habits = _habits.habits.where((h) => h.active).toList();
    final doneToday = habits
        .where((h) => _habits.isCompletedToday(h.id))
        .length;

    _snapshot = AnalyticsSnapshot(
      activeTasks: active,
      completedTasks: completed,
      overdueTasks: overdue,
      upcomingReminders: upcomingReminders,
      totalHabits: habits.length,
      habitsDoneToday: doneToday,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _tasks.removeListener(_recompute);
    _reminders.removeListener(_recompute);
    _habits.removeListener(_recompute);
    super.dispose();
  }
}
