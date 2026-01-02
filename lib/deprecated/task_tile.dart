import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/core/widgets/circular_checkbox.dart';
import 'package:nexus/core/widgets/nexus_card.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:nexus/features/tasks/views/widgets/task_detail_sheet/task_detail_sheet.dart';
import 'package:nexus/features/tasks/views/widgets/task_editor_dialog.dart';
import 'package:provider/provider.dart';

/// A styled task tile following Nexus design system.
/// Features circular checkbox, category tag, time, and edit button.
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task});

  final Task task;

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'work':
        return Colors.red;
      case 'personal':
        return Colors.blue;
      case 'family':
        return Colors.purple;
      case 'health':
        return Colors.green;
      case 'finance':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = context.read<TaskController>();
    final completed = task.statusEnum == TaskStatus.completed;
    final categoryColor = _getCategoryColor(task.categoryId);

    return NexusCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      onTap: () => showTaskDetailSheet(context, task),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular checkbox
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: CircularCheckbox(
              value: completed,
              onChanged: (v) => controller.toggleCompleted(task, v),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  task.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    decoration: completed ? TextDecoration.lineThrough : null,
                    color: completed
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Category tag and time
                Row(
                  children: [
                    // Category tag
                    if (task.categoryId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? categoryColor.withValues(alpha: 0.15)
                              : categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDark
                                ? categoryColor.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          task.categoryId!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? categoryColor.withValues(alpha: 0.9)
                                : categoryColor,
                          ),
                        ),
                      ),
                    // Due time
                    if (task.dueDate != null) ...[
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat.jm().format(task.dueDate!),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Edit button
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () => showTaskEditorDialog(context, task: task),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
