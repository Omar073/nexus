import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/circular_checkbox.dart';
import 'package:nexus/features/tasks/models/task.dart';

/// Task item card for daily tasks view.
/// Shows task title, due time, and actions.
class DailyTaskItem extends StatelessWidget {
  const DailyTaskItem({
    super.key,
    required this.task,
    required this.onToggle,
    this.onSnooze,
    this.onTap,
    this.isOverdue = false,
    this.isCompleted = false,
  });

  final Task task;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onSnooze;
  final VoidCallback? onTap;
  final bool isOverdue;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
            // Checkbox
            if (!isCompleted)
              CircularCheckbox(value: false, onChanged: onToggle)
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.check,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
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
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isOverdue) ...[
                          Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _formatDueTime(task.dueDate!),
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
                    ),
                  ],
                ],
              ),
            ),
            // Snooze button
            if (!isCompleted && onSnooze != null)
              IconButton(
                icon: Icon(
                  Icons.snooze,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                onPressed: onSnooze,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDueTime(DateTime dueDate) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    final hour = dueDate.hour;
    final minute = dueDate.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeStr = '$displayHour:${minute.toString().padLeft(2, '0')} $period';

    if (dueDay == yesterday) {
      return 'Yesterday, $timeStr';
    }
    return timeStr;
  }
}
