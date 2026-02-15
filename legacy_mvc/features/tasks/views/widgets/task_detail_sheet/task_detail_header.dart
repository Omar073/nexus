import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/models/task.dart';

/// Task header showing title and description.
class TaskDetailHeader extends StatelessWidget {
  const TaskDetailHeader({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(task.title, style: Theme.of(context).textTheme.titleLarge),
        if (task.description != null) ...[
          const SizedBox(height: 8),
          Text(task.description!),
        ],
      ],
    );
  }
}
