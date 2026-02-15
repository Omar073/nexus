import 'package:nexus/features/tasks/models/task_enums.dart';

/// Result class for the task editor dialog.
class TaskEditorResult {
  TaskEditorResult({
    required this.title,
    required this.description,
    this.dueDate,
    this.priority,
    this.difficulty,
    this.recurrence = TaskRecurrenceRule.none,
  });

  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskPriority? priority;
  final TaskDifficulty? difficulty;
  final TaskRecurrenceRule recurrence;
}
