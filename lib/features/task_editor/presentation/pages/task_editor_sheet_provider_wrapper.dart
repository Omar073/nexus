import 'package:flutter/material.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/task_editor/presentation/pages/task_editor_sheet.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:provider/provider.dart';

/// Wraps task editor sheet with required providers.
Widget wrapTaskEditorSheetWithRequiredProviders(
  BuildContext context, {
  required TaskEntity? task,
  String? categoryId,
  String? subcategoryId,
}) {
  final taskController = context.read<TaskController>();
  final categoryController = context.read<CategoryController>();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TaskController>.value(value: taskController),
      ChangeNotifierProvider<CategoryController>.value(
        value: categoryController,
      ),
    ],
    child: TaskEditorSheet(
      task: task,
      controller: taskController,
      initialCategoryId: categoryId,
      initialSubcategoryId: subcategoryId,
    ),
  );
}
