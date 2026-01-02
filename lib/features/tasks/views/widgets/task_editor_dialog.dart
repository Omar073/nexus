import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/task_editor/task_editor_sheet.dart';
import 'package:provider/provider.dart';

import 'package:nexus/features/tasks/controllers/category_controller.dart';

/// Shows a bottom sheet modal for creating or editing a task.
/// Follows Nexus design with styled inputs and priority selector.
Future<void> showTaskEditorDialog(BuildContext context, {Task? task}) async {
  final taskController = context.read<TaskController>();
  final categoryController = context.read<CategoryController>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: taskController),
        ChangeNotifierProvider.value(value: categoryController),
      ],
      child: TaskEditorSheet(task: task, controller: taskController),
    ),
  );
}
