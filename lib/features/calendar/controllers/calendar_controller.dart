import 'package:flutter/foundation.dart';
import 'package:nexus/features/reminders/controllers/reminder_controller.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarItem {
  CalendarItem({
    required this.id,
    required this.title,
    required this.when,
    required this.type,
    this.isAllDay = false,
    this.timeString,
  });

  final String id;
  final String title;
  final DateTime when;
  final String type; // 'task' | 'reminder'
  final bool isAllDay;
  final String? timeString;
}

class CalendarController extends ChangeNotifier {
  CalendarController({
    required TaskController tasks,
    required ReminderController reminders,
  }) : _tasks = tasks,
       _reminders = reminders {
    _tasks.addListener(notifyListeners);
    _reminders.addListener(notifyListeners);
  }

  final TaskController _tasks;
  final ReminderController _reminders;

  List<CalendarItem> itemsForDay(DateTime day) {
    // Normalize query day to start of day
    final queryStart = DateTime(day.year, day.month, day.day);
    final queryEnd = queryStart.add(const Duration(days: 1));

    final taskItems = _tasks
        .tasksForStatus(TaskStatus.active)
        .where((t) {
          if (t.startDate == null && t.dueDate != null) {
            final due = t.dueDate!;
            return due.isAfter(queryStart) && due.isBefore(queryEnd) ||
                (due.year == queryStart.year &&
                    due.month == queryStart.month &&
                    due.day == queryStart.day);
          }
          if (t.startDate != null) {
            final start = DateTime(
              t.startDate!.year,
              t.startDate!.month,
              t.startDate!.day,
            );
            final endRaw = t.dueDate ?? t.startDate!;
            final end = DateTime(
              endRaw.year,
              endRaw.month,
              endRaw.day,
            ).add(const Duration(days: 1));
            return start.isBefore(queryEnd) && end.isAfter(queryStart);
          }
          return false;
        })
        .map((t) {
          final isRange =
              t.startDate != null &&
              t.dueDate != null &&
              !isSameDay(t.startDate!, t.dueDate!);
          // It's all day if it's a range OR if dueDate has 00:00 time (legacy logic?)
          // Usually tasks are "All Day" if they don't have a specific due time?
          // For now, let's assume range tasks are "All day" on intermediate days,
          // but might have specific time on due date?
          // Simplified: Treat tasks with duration as All Day for now.
          // Treat single due date tasks as Time specific if they have non-midnight time?
          // Or just check if user asks for time.
          // Let's check if dueTime is midnight (00:00).
          bool isTimeSpecific = false;
          if (t.dueDate != null) {
            isTimeSpecific = !(t.dueDate!.hour == 0 && t.dueDate!.minute == 0);
          }

          return CalendarItem(
            id: t.id,
            title: t.title,
            when: t.dueDate ?? t.startDate ?? day, // fallback
            type: 'task',
            isAllDay: isRange || !isTimeSpecific,
          );
        });

    final reminderItems = _reminders.reminders
        .where((r) => r.time.isAfter(queryStart) && r.time.isBefore(queryEnd))
        .map(
          (r) => CalendarItem(
            id: r.id,
            title: r.title,
            when: r.time,
            type: 'reminder',
            isAllDay: false, // Reminders are time specific
          ),
        );

    final all = [...taskItems, ...reminderItems]
      ..sort((a, b) => a.when.compareTo(b.when));
    return all;
  }

  @override
  void dispose() {
    _tasks.removeListener(notifyListeners);
    _reminders.removeListener(notifyListeners);
    super.dispose();
  }
}
