import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:nexus/features/tasks/views/widgets/tiles/task_item.dart';
import 'package:nexus/features/tasks/views/widgets/task_editor_dialog.dart';

class CategorySectionTaskItem extends StatelessWidget {
  const CategorySectionTaskItem({
    super.key,
    required this.task,
    required this.taskController,
    this.isCompletedTab = false,
    this.animateExit = false,
  });

  final Task task;
  final TaskController taskController;
  final bool isCompletedTab;
  final bool animateExit;

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
        child: TaskItem(
          task: task,
          isCompleted: isCompleted,
          isOverdue: isOverdue,
          animateExit: animateExit,
          onToggle: (value) => taskController.toggleCompleted(task, value),
          onTap: () => showTaskEditorDialog(context, task: task),
        ),
      ),
    );
  }
}
