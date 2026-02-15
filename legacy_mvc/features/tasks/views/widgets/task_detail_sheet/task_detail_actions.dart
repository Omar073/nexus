import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';

/// Delete and close action buttons for task detail sheet.
class TaskDetailActions extends StatelessWidget {
  const TaskDetailActions({
    super.key,
    required this.task,
    required this.controller,
    required this.onClose,
  });

  final Task task;
  final TaskController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () async {
            onClose();
            await controller.deleteTask(task);
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete'),
        ),
        const Spacer(),
        FilledButton(onPressed: onClose, child: const Text('Cancel')),
      ],
    );
  }
}
