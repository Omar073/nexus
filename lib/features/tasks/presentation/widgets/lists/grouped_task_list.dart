import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/categories/data/models/category.dart';
import 'package:nexus/features/tasks/presentation/widgets/navigation/jump_to_category_button.dart';
import 'package:nexus/features/tasks/presentation/widgets/sections/category_section.dart';
import 'package:nexus/features/tasks/presentation/widgets/states/empty_tasks_state.dart';

/// List of tasks grouped under category headers.
class GroupedTaskList extends StatelessWidget {
  const GroupedTaskList({
    super.key,
    required this.tabIndex,
    required this.tasks,
    required this.categories,
    required this.taskController,
    required this.categoryKeys,
    required this.onShowDrawer,
    required this.emptyMessage,
    required this.emptyIcon,
    this.categoryIdToRootId = const {},
    this.isCompletedTab = false,
    this.animateExit = false,
    this.selectionMode = false,
    this.selectedTaskIds = const <String>{},
    this.onTaskLongPress,
    this.onTaskSelectionToggle,
  });

  final int tabIndex;
  final List<TaskEntity> tasks;
  final List<Category> categories;

  /// Maps any category id (root or subcategory) to its root category id.
  /// Used so tasks with a subcategory id in [TaskEntity.categoryId] still
  /// group under the correct root section.
  final Map<String, String> categoryIdToRootId;
  final TaskController taskController;
  final Map<String, GlobalKey> categoryKeys;
  final void Function(Map<String?, int>, List<Category>) onShowDrawer;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool isCompletedTab;
  final bool animateExit;
  final bool selectionMode;
  final Set<String> selectedTaskIds;
  final void Function(TaskEntity task)? onTaskLongPress;
  final void Function(TaskEntity task)? onTaskSelectionToggle;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return EmptyTasksState(message: emptyMessage, icon: emptyIcon);
    }

    // Group tasks by category. Tasks whose categoryId no longer exists in the
    // current categories list are treated as "Uncategorized" so they still
    // appear in the list instead of disappearing.
    final groupedTasks = _groupTasksByCategory(tasks);
    final taskCounts = _calculateTaskCounts(groupedTasks);

    // Ensure keys exist for all categories
    _ensureCategoryKeys();

    // Build list of category sections
    final List<Widget> sections = [];

    // Jump to category button
    sections.add(
      JumpToCategoryButton(onTap: () => onShowDrawer(taskCounts, categories)),
    );

    // Category sections
    for (final category in categories) {
      final categoryTasks = groupedTasks[category.id] ?? [];
      if (categoryTasks.isNotEmpty) {
        sections.add(
          CategorySection(
            sectionKey: categoryKeys['$tabIndex:${category.id}']!,
            title: category.name,
            tasks: categoryTasks,
            taskController: taskController,
            categoryId: category.id,
            isCompletedTab: isCompletedTab,
            animateExit: animateExit,
            selectionMode: selectionMode,
            selectedTaskIds: selectedTaskIds,
            onTaskLongPress: onTaskLongPress,
            onTaskSelectionToggle: onTaskSelectionToggle,
          ),
        );
      }
    }

    // Uncategorized section
    if (groupedTasks[null]?.isNotEmpty ?? false) {
      sections.add(
        CategorySection(
          sectionKey: categoryKeys['$tabIndex:null']!,
          title: 'Uncategorized',
          tasks: groupedTasks[null]!,
          taskController: taskController,
          isCompletedTab: isCompletedTab,
          animateExit: animateExit,
          selectionMode: selectionMode,
          selectedTaskIds: selectedTaskIds,
          onTaskLongPress: onTaskLongPress,
          onTaskSelectionToggle: onTaskSelectionToggle,
        ),
      );
    }

    sections.add(const SizedBox(height: 500));

    return SingleChildScrollView(
      primary: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sections,
      ),
    );
  }

  Map<String?, List<TaskEntity>> _groupTasksByCategory(List<TaskEntity> tasks) {
    final Map<String?, List<TaskEntity>> grouped = {};
    final validRootIds = categories.map((c) => c.id).toSet();

    for (final task in tasks) {
      final String? categoryKey = _resolveRootCategoryId(
        task.categoryId,
        validRootIds,
      );
      grouped.putIfAbsent(categoryKey, () => []).add(task);
    }

    return grouped;
  }

  /// Resolves a task's categoryId to the root category id used for grouping.
  /// Handles: null, root id, subcategory id (including legacy data where
  /// categoryId holds the sub id), or missing/deleted category → null.
  String? _resolveRootCategoryId(String? categoryId, Set<String> validRootIds) {
    if (categoryId == null) return null;
    if (validRootIds.contains(categoryId)) return categoryId;
    final rootId = categoryIdToRootId[categoryId];
    return rootId != null && validRootIds.contains(rootId) ? rootId : null;
  }

  Map<String?, int> _calculateTaskCounts(
    Map<String?, List<TaskEntity>> grouped,
  ) {
    return grouped.map((key, value) => MapEntry(key, value.length));
  }

  void _ensureCategoryKeys() {
    for (final category in categories) {
      categoryKeys.putIfAbsent('$tabIndex:${category.id}', () => GlobalKey());
    }
    categoryKeys.putIfAbsent('$tabIndex:null', () => GlobalKey());
  }
}
