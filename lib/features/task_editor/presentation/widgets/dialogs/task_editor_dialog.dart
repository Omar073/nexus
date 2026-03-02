import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/task_editor/presentation/pages/task_editor_sheet.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:provider/provider.dart';

/// Shows a bottom sheet modal for creating or editing a task.
/// Follows Nexus design with styled inputs and priority selector.
Future<void> showTaskEditorDialog(
  BuildContext context, {
  TaskEntity? task,
  String? categoryId,
  String? subcategoryId,
}) async {
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
      child: TaskEditorSheet(
        task: task,
        controller: taskController,
        initialCategoryId: categoryId,
        initialSubcategoryId: subcategoryId,
      ),
    ),
  );
}
