import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/views/task_editor/task_editor_sheet.dart';
import 'package:provider/provider.dart';

/// Shows a bottom sheet modal for creating or editing a task.
/// Follows Nexus design with styled inputs and priority selector.
Future<void> showTaskEditorDialog(BuildContext context, {Task? task}) async {
  final controller = context.read<TaskController>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        TaskEditorSheet(task: task, controller: controller),
  );
}
