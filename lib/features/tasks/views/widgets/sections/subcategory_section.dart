import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/views/widgets/sections/category_section_task_item.dart';

/// A collapsible subcategory section within a category.
class SubcategorySection extends StatelessWidget {
  const SubcategorySection({
    super.key,
    required this.name,
    required this.tasks,
    required this.taskController,
    required this.isExpanded,
    required this.onToggle,
    this.isCompletedTab = false,
    this.animateExit = false,
  });

  final String name;
  final List<Task> tasks;
  final TaskController taskController;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool isCompletedTab;
  final bool animateExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subcategory Header
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${tasks.length})',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Subcategory Tasks
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    children: tasks
                        .map(
                          (t) => CategorySectionTaskItem(
                            task: t,
                            taskController: taskController,
                            isCompletedTab: isCompletedTab,
                            animateExit: animateExit,
                          ),
                        )
                        .toList(),
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}
