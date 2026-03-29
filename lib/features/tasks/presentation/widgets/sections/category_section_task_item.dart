import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:nexus/features/tasks/presentation/extensions/task_entity_extensions.dart';
import 'package:nexus/features/tasks/presentation/widgets/tiles/task_item.dart';
import 'package:nexus/features/task_editor/presentation/widgets/dialogs/task_editor_dialog.dart';

/// Single task row inside a category section.

class CategorySectionTaskItem extends StatelessWidget {
  const CategorySectionTaskItem({
    super.key,
    required this.task,
    required this.taskController,
    this.isCompletedTab = false,
    this.animateExit = false,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
    this.onLongPress,
  });

  final TaskEntity task;
  final TaskController taskController;
  final bool isCompletedTab;
  final bool animateExit;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;
  final VoidCallback? onLongPress;

  void _handleDelete(BuildContext context, TaskEntity task) {
    taskController.deleteTask(task);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            taskController.restoreTask(task);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          child: Row(
            children: [
              const Expanded(child: Text('Task deleted')),
              Text(
                'Click to undo',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleToggle(BuildContext context, bool newValue) {
    final wasCompleted = task.statusEnum == TaskStatus.completed;
    taskController.toggleCompleted(task, newValue);

    // Show undo snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Undo the toggle
            taskController.toggleCompleted(task, wasCompleted);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          child: Row(
            children: [
              Expanded(
                child: Text(newValue ? 'Task completed' : 'Task uncompleted'),
              ),
              Text(
                'Click to undo',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.statusEnum == TaskStatus.completed;
    final isOverdue =
        !isCompleted &&
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: isCompletedTab ? 0.7 : 1.0,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: onLongPress,
          child: TaskItem(
            task: task,
            isCompleted: isCompleted,
            isOverdue: isOverdue,
            animateExit: animateExit,
            onToggle: (value) => _handleToggle(context, value),
            onTap: selectionMode
                ? () => onSelectionToggle?.call()
                : () => showTaskEditorDialog(context, task: task),
            onDelete: () => _handleDelete(context, task),
            isSelected: selectionMode && isSelected,
          ),
        ),
      ),
    );
  }
}
