import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/features/dashboard/views/widgets/upcoming_task_card.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:provider/provider.dart';

/// Dashboard section showing upcoming tasks.
class DashboardTasksSection extends StatelessWidget {
  const DashboardTasksSection({super.key, required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(
                Icons.task_alt,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No upcoming tasks',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final taskController = context.read<TaskController>();
    return Column(
      children: tasks.take(5).map<Widget>((t) {
        final isCompleted = t.statusEnum == TaskStatus.completed;
        final isHighPriority = t.priorityEnum == TaskPriority.high;
        final categoryLabel = t.categoryId ?? 'Task';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: UpcomingTaskCard(
            title: t.title,
            subtitle: t.dueDate != null
                ? 'Due ${DateFormat.jm().format(t.dueDate!)} • $categoryLabel'
                : categoryLabel,
            isCompleted: isCompleted,
            isHighPriority: isHighPriority,
            onToggle: (value) {
              taskController.toggleCompleted(t, value);
            },
          ),
        );
      }).toList(),
    );
  }
}
