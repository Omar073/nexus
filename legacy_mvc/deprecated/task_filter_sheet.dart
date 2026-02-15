import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:provider/provider.dart';

/// Shows a modal bottom sheet with task filter options.
Future<void> showTaskFilterSheet(BuildContext context) async {
  final controller = context.read<TaskController>();
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      var overdueOnly = controller.filterOverdueOnly;
      var priority = controller.filterPriority;
      return Padding(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (sheetContext, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Overdue only'),
                  value: overdueOnly,
                  onChanged: (v) {
                    setState(() => overdueOnly = v);
                    controller.setOverdueOnly(v);
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<TaskPriority?>(
                  initialValue: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Any')),
                    DropdownMenuItem(
                      value: TaskPriority.high,
                      child: Text('High'),
                    ),
                    DropdownMenuItem(
                      value: TaskPriority.medium,
                      child: Text('Medium'),
                    ),
                    DropdownMenuItem(
                      value: TaskPriority.low,
                      child: Text('Low'),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => priority = v);
                    controller.setPriorityFilter(v);
                  },
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
