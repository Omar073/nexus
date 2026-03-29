import 'package:flutter/material.dart';
import 'package:nexus/features/categories/data/models/category.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:nexus/features/tasks/presentation/extensions/task_entity_extensions.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/presentation/widgets/bottom_sheets/move_tasks_to_category_sheet.dart';

/// Applies delete/move/complete to selected tasks.

class TaskBulkActions {
  TaskBulkActions._();

  static Future<void> deleteSelected({
    required BuildContext context,
    required TaskController controller,
    required List<String> selectedIds,
    required VoidCallback onCleared,
  }) async {
    final tasks = selectedIds
        .map((id) => controller.byId(id))
        .whereType<TaskEntity>()
        .toList();
    onCleared();

    for (final task in tasks) {
      await controller.deleteTask(task);
    }
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            for (final task in tasks) {
              await controller.restoreTask(task);
            }
            messenger.hideCurrentSnackBar();
          },
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tasks.length == 1
                      ? 'Task deleted'
                      : '${tasks.length} tasks deleted',
                ),
              ),
              Text(
                'Click to undo',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<void> toggleCompletedForSelected({
    required TaskController controller,
    required List<String> selectedIds,
    required VoidCallback onCleared,
  }) async {
    onCleared();
    for (final id in selectedIds) {
      final task = controller.byId(id);
      if (task != null) {
        final isCompleted = task.statusEnum == TaskStatus.completed;
        await controller.toggleCompleted(task, !isCompleted);
      }
    }
  }

  static Future<void> moveSelectedToCategory({
    required BuildContext context,
    required TaskController controller,
    required List<String> selectedIds,
    required List<Category> categories,
    required VoidCallback onCleared,
  }) async {
    if (selectedIds.isEmpty) return;

    final selectedId = await MoveTasksToCategorySheet.show(
      context,
      categories: categories,
    );

    if (!context.mounted) return;

    onCleared();
    for (final id in selectedIds) {
      final task = controller.byId(id);
      if (task != null) {
        await controller.updateTask(
          task,
          categoryId: selectedId,
          subcategoryId: null,
        );
      }
    }
  }
}
