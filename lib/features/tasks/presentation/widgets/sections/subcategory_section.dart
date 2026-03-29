import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/presentation/widgets/sections/category_section_task_item.dart';
import 'package:nexus/features/task_editor/presentation/widgets/dialogs/task_editor_dialog.dart';

/// Nested grouping when parent/child categories exist.
class SubcategorySection extends StatelessWidget {
  const SubcategorySection({
    super.key,
    required this.name,
    required this.tasks,
    required this.taskController,
    required this.isExpanded,
    required this.onToggle,
    this.categoryId,
    this.subcategoryId,
    this.isCompletedTab = false,
    this.animateExit = false,
    this.selectionMode = false,
    this.selectedTaskIds = const <String>{},
    this.onTaskLongPress,
    this.onTaskSelectionToggle,
  });

  final String name;
  final List<TaskEntity> tasks;
  final TaskController taskController;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String? categoryId;
  final String? subcategoryId;
  final bool isCompletedTab;
  final bool animateExit;
  final bool selectionMode;
  final Set<String> selectedTaskIds;
  final void Function(TaskEntity task)? onTaskLongPress;
  final void Function(TaskEntity task)? onTaskSelectionToggle;

  void _handleAddTask(BuildContext context) {
    showTaskEditorDialog(
      context,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
    );
  }

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
                const Spacer(),
                if (subcategoryId != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _handleAddTask(context),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: Icon(
                          Icons.add,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
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
                            selectionMode: selectionMode,
                            isSelected: selectedTaskIds.contains(t.id),
                            onSelectionToggle: onTaskSelectionToggle == null
                                ? null
                                : () => onTaskSelectionToggle!(t),
                            onLongPress: onTaskLongPress == null
                                ? null
                                : () => onTaskLongPress!(t),
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
