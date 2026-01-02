import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/views/widgets/task_filter_sheet.dart';
import 'package:provider/provider.dart';

/// Search bar widget for filtering tasks with text search and priority filters.
class TaskSearchBar extends StatelessWidget {
  const TaskSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search tasks',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            tooltip: 'Filter',
            onPressed: () => showTaskFilterSheet(context),
            icon: const Icon(Icons.filter_list),
          ),
        ),
        onChanged: controller.setQuery,
      ),
    );
  }
}
