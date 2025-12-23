import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:nexus/features/tasks/views/widgets/task_tile.dart';
import 'package:provider/provider.dart';

/// A tab that displays a list of tasks filtered by status.
class TaskListTab extends StatelessWidget {
  const TaskListTab({super.key, required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();
    final tasks = controller.tasksForStatus(status);

    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks'));
    }

    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskTile(task: task);
      },
    );
  }
}
