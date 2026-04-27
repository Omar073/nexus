import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/bottom_sheet/nexus_bottom_sheet.dart';
import 'package:nexus/features/categories/data/models/category.dart';
import 'package:nexus/features/categories/presentation/widgets/category_drawer.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/presentation/widgets/helpers/category_scroll_helper.dart';

void showTasksCategoryDrawer({
  required BuildContext context,
  required TaskController taskController,
  required CategoryScrollHelper scrollHelper,
  required bool mounted,
  required Map<String?, int> taskCounts,
  required List<Category> sortedCategories,
}) {
  showNexusBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.6,
      minChildSize: 0.25,
      builder: (context, scrollController) => CategoryDrawer(
        scrollController: scrollController,
        onCategorySelected: (categoryId) =>
            scrollHelper.scrollToCategory(categoryId, mounted: mounted),
        taskCountByCategory: taskCounts,
        sortedCategories: sortedCategories,
        onClearTasks: taskController.clearCategoryOnTasks,
      ),
    ),
  );
}

List<TaskEntity> tasksForCurrentTab({
  required int tabIndex,
  required List<TaskEntity> pendingTasks,
  required List<TaskEntity> allTasks,
  required List<TaskEntity> completedTasks,
}) {
  return switch (tabIndex) {
    0 => pendingTasks,
    1 => allTasks,
    2 => completedTasks,
    _ => allTasks,
  };
}
