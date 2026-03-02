import 'package:intl/intl.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';

/// Utility class for formatting task-related dates and durations.
class TaskDateFormatter {
  TaskDateFormatter._();

  /// Formats the task's start and/or due date into a human-readable string.
  /// Returns an empty string if both dates are null.
  static String formatDuration(TaskEntity task) {
    if (task.startDate == null && task.dueDate == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String format(DateTime d) {
      final date = DateTime(d.year, d.month, d.day);
      if (date == today) {
        return 'Today';
      }
      final diff = date.difference(today).inDays.abs();
      if (diff < 7) {
        return DateFormat('EEE, MMM d').format(d);
      }
      return DateFormat('MMM d').format(d);
    }

    if (task.startDate != null && task.dueDate != null) {
      return '${format(task.startDate!)} - ${format(task.dueDate!)}';
    }

    if (task.startDate != null) {
      return 'Starts ${format(task.startDate!)}';
    }

    return 'Due ${format(task.dueDate!)}';
  }
}
