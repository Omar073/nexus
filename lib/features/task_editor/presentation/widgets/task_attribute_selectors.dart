import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:nexus/features/task_editor/presentation/widgets/components/task_priority_button.dart';

/// Priority, due date, and reminder chips for the editor.

class TaskAttributeSelectors extends StatelessWidget {
  const TaskAttributeSelectors({
    super.key,
    required this.priority,
    required this.difficulty,
    required this.onPriorityChanged,
    required this.onDifficultyChanged,
  });

  final TaskPriority? priority;
  final TaskDifficulty? difficulty;
  final ValueChanged<TaskPriority?> onPriorityChanged;
  final ValueChanged<TaskDifficulty?> onDifficultyChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Priority selector
        Text(
          'Priority',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TaskPriorityButton(
              label: 'Low',
              color: Colors.green,
              isSelected: priority == TaskPriority.low,
              onTap: () => onPriorityChanged(
                priority == TaskPriority.low ? null : TaskPriority.low,
              ),
            ),
            const SizedBox(width: 8),
            TaskPriorityButton(
              label: 'Medium',
              color: Colors.orange,
              isSelected: priority == TaskPriority.medium,
              onTap: () => onPriorityChanged(
                priority == TaskPriority.medium ? null : TaskPriority.medium,
              ),
            ),
            const SizedBox(width: 8),
            TaskPriorityButton(
              label: 'High',
              color: Colors.red,
              isSelected: priority == TaskPriority.high,
              onTap: () => onPriorityChanged(
                priority == TaskPriority.high ? null : TaskPriority.high,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Difficulty selector
        Text(
          'Difficulty',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TaskPriorityButton(
              label: 'Easy',
              color: Colors.teal,
              isSelected: difficulty == TaskDifficulty.low,
              onTap: () => onDifficultyChanged(
                difficulty == TaskDifficulty.low ? null : TaskDifficulty.low,
              ),
            ),
            const SizedBox(width: 8),
            TaskPriorityButton(
              label: 'Medium',
              color: Colors.blue,
              isSelected: difficulty == TaskDifficulty.medium,
              onTap: () => onDifficultyChanged(
                difficulty == TaskDifficulty.medium
                    ? null
                    : TaskDifficulty.medium,
              ),
            ),
            const SizedBox(width: 8),
            TaskPriorityButton(
              label: 'Hard',
              color: Colors.purple,
              isSelected: difficulty == TaskDifficulty.high,
              onTap: () => onDifficultyChanged(
                difficulty == TaskDifficulty.high ? null : TaskDifficulty.high,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
