import 'package:flutter/foundation.dart';
import 'package:nexus/features/reminders/controllers/reminder_controller.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';

class CalendarItem {
  CalendarItem({
    required this.id,
    required this.title,
    required this.when,
    required this.type,
  });

  final String id;
  final String title;
  final DateTime when;
  final String type; // 'task' | 'reminder'
}

class CalendarController extends ChangeNotifier {
  CalendarController({required TaskController tasks, required ReminderController reminders})
      : _tasks = tasks,
        _reminders = reminders {
    _tasks.addListener(notifyListeners);
    _reminders.addListener(notifyListeners);
  }

  final TaskController _tasks;
  final ReminderController _reminders;

  List<CalendarItem> itemsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final taskItems = _tasks
        .tasksForStatus(TaskStatus.active)
        .where((t) => t.dueDate != null)
        .where((t) => t.dueDate!.isAfter(start) && t.dueDate!.isBefore(end))
        .map((t) => CalendarItem(id: t.id, title: t.title, when: t.dueDate!, type: 'task'));

    final reminderItems = _reminders.reminders
        .where((r) => r.time.isAfter(start) && r.time.isBefore(end))
        .map((r) => CalendarItem(id: r.id, title: r.title, when: r.time, type: 'reminder'));

    final all = [...taskItems, ...reminderItems]..sort((a, b) => a.when.compareTo(b.when));
    return all;
  }

  @override
  void dispose() {
    _tasks.removeListener(notifyListeners);
    _reminders.removeListener(notifyListeners);
    super.dispose();
  }
}


