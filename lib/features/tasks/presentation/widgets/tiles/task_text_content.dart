import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/presentation/widgets/tiles/task_date_row.dart';

/// Title and notes text styling inside a task item.
class TaskTextContent extends StatelessWidget {
  const TaskTextContent({
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
    final hasDates = task.startDate != null || task.dueDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isCompleted
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            decorationColor: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (hasDates) ...[
          const SizedBox(height: 4),
          TaskDateRow(
            task: task,
            isCompleted: isCompleted,
            isOverdue: isOverdue,
          ),
        ],
      ],
    );
  }
}
