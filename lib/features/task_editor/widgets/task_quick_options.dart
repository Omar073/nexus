import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:nexus/features/task_editor/widgets/task_option_chip.dart';

class TaskQuickOptions extends StatelessWidget {
  const TaskQuickOptions({
    super.key,
    required this.startDate,
    required this.dueDate,
    required this.dueTime,
    required this.recurrence,
    required this.onPickStartDate,
    required this.onPickDueDate,
    required this.onPickDueTime,
    required this.onPickRecurrence,
  });

  final DateTime? startDate;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
  final TaskRecurrenceRule recurrence;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickDueDate;
  final VoidCallback onPickDueTime;
  final VoidCallback onPickRecurrence;

  String _getRecurrenceLabel(TaskRecurrenceRule rule) {
    switch (rule) {
      case TaskRecurrenceRule.daily:
        return 'Daily';
      case TaskRecurrenceRule.weekly:
        return 'Weekly';
      default:
        return 'Repeat';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Start date chip
        TaskOptionChip(
          icon: Icons.calendar_today_outlined,
          label: startDate != null
              ? DateFormat('MMM d').format(startDate!)
              : 'Start date',
          isSelected: startDate != null,
          onTap: onPickStartDate,
        ),
        // Due date chip
        TaskOptionChip(
          icon: Icons.calendar_today,
          label: dueDate != null
              ? DateFormat('MMM d').format(dueDate!)
              : 'Due date',
          isSelected: dueDate != null,
          onTap: onPickDueDate,
        ),
        // Due time chip
        TaskOptionChip(
          icon: Icons.schedule,
          label: dueTime != null ? dueTime!.format(context) : 'Time',
          isSelected: dueTime != null,
          onTap: onPickDueTime,
        ),
        // Repeat chip
        TaskOptionChip(
          icon: Icons.repeat,
          label: _getRecurrenceLabel(recurrence),
          isSelected: recurrence != TaskRecurrenceRule.none,
          onTap: onPickRecurrence,
        ),
      ],
    );
  }
}
