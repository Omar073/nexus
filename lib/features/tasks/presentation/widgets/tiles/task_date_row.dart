import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/presentation/utils/task_date_formatter.dart';

/// Row displaying task date information with optional overdue indicator.
class TaskDateRow extends StatelessWidget {
  const TaskDateRow({
    super.key,
    required this.task,
    required this.isCompleted,
    required this.isOverdue,
  });

  final TaskEntity task;
  final bool isCompleted;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (isOverdue) ...[
          Icon(Icons.error_outline, size: 14, color: Colors.red.shade400),
          const SizedBox(width: 4),
        ],
        Text(
          TaskDateFormatter.formatDuration(task),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isOverdue
                ? Colors.red.shade400
                : isCompleted
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
