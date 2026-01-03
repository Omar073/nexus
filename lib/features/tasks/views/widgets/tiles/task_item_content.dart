import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/circular_checkbox.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/utils/task_date_formatter.dart';

/// The content layout of a task item card.
/// Shows checkbox, title, and optional date information.
class TaskItemContent extends StatelessWidget {
  const TaskItemContent({
    super.key,
    required this.task,
    required this.isCompleted,
    required this.isOverdue,
    required this.onToggle,
    this.onTap,
  });

  final Task task;
  final bool isCompleted;
  final bool isOverdue;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isCompleted
            ? (isDark ? Colors.black : Colors.grey.shade50)
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: isCompleted ? 0.05 : 0.1)
              : (isCompleted ? Colors.grey.shade100 : Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // Expanded tap area for checkbox - makes it easier to toggle
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onToggle(!isCompleted),
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
              child: CircularCheckbox(value: isCompleted, onChanged: onToggle),
            ),
          ),
          // Rest of the card is tappable for edit
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: _TaskTextContent(
                task: task,
                isCompleted: isCompleted,
                isOverdue: isOverdue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Text content section of the task item (title and dates).
class _TaskTextContent extends StatelessWidget {
  const _TaskTextContent({
    required this.task,
    required this.isCompleted,
    required this.isOverdue,
  });

  final Task task;
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
          _TaskDateRow(
            task: task,
            isCompleted: isCompleted,
            isOverdue: isOverdue,
          ),
        ],
      ],
    );
  }
}

/// Row displaying task date information with optional overdue indicator.
class _TaskDateRow extends StatelessWidget {
  const _TaskDateRow({
    required this.task,
    required this.isCompleted,
    required this.isOverdue,
  });

  final Task task;
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
