import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/bottom_sheet/nexus_bottom_sheet.dart';
import 'package:nexus/features/task_editor/presentation/pages/task_editor_sheet_provider_wrapper.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';

/// Shows a bottom sheet modal for creating or editing a task.
/// Follows Nexus design with styled inputs and priority selector.
Future<void> showTaskEditorDialog(
  BuildContext context, {
  TaskEntity? task,
  String? categoryId,
  String? subcategoryId,
}) async {
  await showNexusBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => wrapTaskEditorSheetWithRequiredProviders(
      context,
      task: task,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
    ),
  );
}
