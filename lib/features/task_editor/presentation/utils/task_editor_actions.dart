import 'package:flutter/material.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:nexus/features/task_editor/presentation/utils/task_editor_pickers.dart';
import 'package:nexus/features/task_editor/presentation/widgets/dialogs/task_category_name_dialog.dart';

Future<String?> showCreateTaskCategoryDialog({
  required BuildContext context,
  required CategoryController categoryController,
  String? parentId,
}) async {
  final isSubcategory = parentId != null;
  final result = await showTaskCategoryNameDialog(
    context,
    isSubcategory: isSubcategory,
  );
  if (result == null || result.isEmpty) {
    return null;
  }
  final category = await categoryController.createCategory(
    result,
    parentId: parentId,
  );
  return category.id;
}

Future<DateTime?> pickTaskStartDate(
  BuildContext context, {
  DateTime? currentStartDate,
}) {
  return pickTaskDate(context, initialDate: currentStartDate ?? DateTime.now());
}

Future<DateTime?> pickTaskDueDate(
  BuildContext context, {
  DateTime? currentDueDate,
}) {
  return pickTaskDate(context, initialDate: currentDueDate ?? DateTime.now());
}

Future<TimeOfDay?> pickTaskTime(
  BuildContext context, {
  TimeOfDay? currentDueTime,
}) {
  return pickTaskDueTime(
    context,
    initialTime: currentDueTime ?? TimeOfDay.now(),
  );
}

Future<TaskRecurrenceRule?> pickTaskRecurrenceRule(BuildContext context) {
  return pickTaskRecurrence(context);
}
