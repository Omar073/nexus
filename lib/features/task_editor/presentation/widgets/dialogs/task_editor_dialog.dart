import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/task_editor/presentation/pages/task_editor_sheet.dart';

/// Shows a bottom sheet modal for creating or editing a task.
/// Follows Nexus design with styled inputs and priority selector.
Future<void> showTaskEditorDialog(
  BuildContext context, {
  TaskEntity? task,
  String? categoryId,
  String? subcategoryId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => TaskEditorSheet.wrapWithRequiredProviders(
      context,
      task: task,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
    ),
  );
}
