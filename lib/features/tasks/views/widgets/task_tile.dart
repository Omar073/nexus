import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:nexus/features/tasks/views/widgets/task_detail_sheet/task_detail_sheet.dart';
import 'package:nexus/features/tasks/views/widgets/task_editor_dialog.dart';
import 'package:provider/provider.dart';

/// A list tile widget for displaying a single task.
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TaskController>();
    final completed = task.statusEnum == TaskStatus.completed;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      horizontalTitleGap: 4,
      leading: Checkbox(
        value: completed,
        onChanged: (v) => controller.toggleCompleted(task, v ?? false),
      ),
      title: Text(task.title, maxLines: 3, overflow: TextOverflow.ellipsis),
      subtitle: task.description == null
          ? null
          : Text(
              task.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: IconButton(
        tooltip: 'Edit task',
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => showTaskEditorDialog(context, task: task),
      ),
      onTap: () => showTaskDetailSheet(context, task),
    );
  }
}
