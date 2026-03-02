import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/circular_checkbox.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/presentation/widgets/tiles/task_text_content.dart';
import 'package:nexus/features/tasks/presentation/widgets/tiles/task_more_menu.dart';

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
    this.onDelete,
    this.isSelected = false,
  });

  final TaskEntity task;
  final bool isCompleted;
  final bool isOverdue;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseBorderColor = isDark
        ? Colors.white.withValues(alpha: isCompleted ? 0.05 : 0.1)
        : (isCompleted ? Colors.grey.shade100 : Colors.grey.shade200);

    final borderColor = isSelected
        ? theme.colorScheme.primary
        : baseBorderColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isCompleted
            ? (isDark ? Colors.black : Colors.grey.shade50)
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
              child: TaskTextContent(
                task: task,
                isCompleted: isCompleted,
                isOverdue: isOverdue,
              ),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            TaskMoreMenu(onDelete: onDelete!),
          ],
        ],
      ),
    );
  }
}
