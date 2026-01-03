import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/category.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/views/widgets/navigation/jump_to_category_button.dart';
import 'package:nexus/features/tasks/views/widgets/sections/category_section.dart';
import 'package:nexus/features/tasks/views/widgets/states/empty_tasks_state.dart';

/// Widget for displaying a grouped list of tasks by category.
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
    this.isCompletedTab = false,
    this.animateExit = false,
  });

  final int tabIndex;
  final List<Task> tasks;
  final List<Category> categories;
  final TaskController taskController;
  final Map<String, GlobalKey> categoryKeys;
  final void Function(Map<String?, int>, List<Category>) onShowDrawer;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool isCompletedTab;
  final bool animateExit;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return EmptyTasksState(message: emptyMessage, icon: emptyIcon);
    }

    // Group tasks by category
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
            isCompletedTab: isCompletedTab,
            animateExit: animateExit,
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

  Map<String?, List<Task>> _groupTasksByCategory(List<Task> tasks) {
    final Map<String?, List<Task>> grouped = {};
    for (final task in tasks) {
      grouped.putIfAbsent(task.categoryId, () => []).add(task);
    }
    return grouped;
  }

  Map<String?, int> _calculateTaskCounts(Map<String?, List<Task>> grouped) {
    return grouped.map((key, value) => MapEntry(key, value.length));
  }

  void _ensureCategoryKeys() {
    for (final category in categories) {
      categoryKeys.putIfAbsent('$tabIndex:${category.id}', () => GlobalKey());
    }
    categoryKeys.putIfAbsent('$tabIndex:null', () => GlobalKey());
  }
}
