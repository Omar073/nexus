import 'package:flutter/material.dart';
import 'package:nexus/features/categories/data/models/category.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/presentation/widgets/helpers/sliver_tab_bar_delegate.dart';
import 'package:nexus/features/tasks/presentation/widgets/lists/grouped_task_list.dart';
import 'package:nexus/features/tasks/presentation/widgets/sections/tasks_header.dart';

/// Category-grouped task list for one filter tab.

class TasksTabBody extends StatelessWidget {
  const TasksTabBody({
    super.key,
    required this.tabController,
    required this.pendingTasks,
    required this.completedTasks,
    required this.categories,
    required this.categoryIdToRootId,
    required this.taskController,
    required this.categoryKeys,
    required this.onShowDrawer,
    required this.selectionMode,
    required this.selectedTaskIds,
    required this.onTaskLongPress,
    required this.onTaskSelectionToggle,
  });

  final TabController tabController;
  final List<TaskEntity> pendingTasks;
  final List<TaskEntity> completedTasks;
  final List<Category> categories;

  /// Maps any category id (root or sub) to root id so tasks group under the right section.
  final Map<String, String> categoryIdToRootId;
  final TaskController taskController;
  final Map<String, GlobalKey> categoryKeys;
  final void Function(Map<String?, int>, List<Category>) onShowDrawer;
  final bool selectionMode;
  final Set<String> selectedTaskIds;
  final void Function(TaskEntity) onTaskLongPress;
  final void Function(TaskEntity) onTaskSelectionToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allTasks = [...pendingTasks, ...completedTasks];

    return NestedScrollView(
      floatHeaderSlivers: true,
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        const SliverToBoxAdapter(child: TasksHeader()),
        SliverPersistentHeader(
          pinned: true,
          delegate: SliverTabBarDelegate(
            TabBar(
              controller: tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: 'Pending (${pendingTasks.length})'),
                Tab(text: 'All (${allTasks.length})'),
                Tab(text: 'Completed (${completedTasks.length})'),
              ],
            ),
            backgroundColor: theme.scaffoldBackgroundColor,
          ),
        ),
      ],
      body: TabBarView(
        controller: tabController,
        children: [
          GroupedTaskList(
            tabIndex: 0,
            tasks: pendingTasks,
            categories: categories,
            categoryIdToRootId: categoryIdToRootId,
            taskController: taskController,
            categoryKeys: categoryKeys,
            onShowDrawer: onShowDrawer,
            emptyMessage: 'No pending tasks',
            emptyIcon: Icons.check_circle_outline,
            animateExit: true,
            selectionMode: selectionMode,
            selectedTaskIds: selectedTaskIds,
            onTaskLongPress: onTaskLongPress,
            onTaskSelectionToggle: onTaskSelectionToggle,
          ),
          GroupedTaskList(
            tabIndex: 1,
            tasks: allTasks,
            categories: categories,
            categoryIdToRootId: categoryIdToRootId,
            taskController: taskController,
            categoryKeys: categoryKeys,
            onShowDrawer: onShowDrawer,
            emptyMessage: 'No tasks yet',
            emptyIcon: Icons.task_alt,
            selectionMode: selectionMode,
            selectedTaskIds: selectedTaskIds,
            onTaskLongPress: onTaskLongPress,
            onTaskSelectionToggle: onTaskSelectionToggle,
          ),
          GroupedTaskList(
            tabIndex: 2,
            tasks: completedTasks,
            categories: categories,
            categoryIdToRootId: categoryIdToRootId,
            taskController: taskController,
            categoryKeys: categoryKeys,
            onShowDrawer: onShowDrawer,
            emptyMessage: 'No completed tasks',
            emptyIcon: Icons.done_all,
            isCompletedTab: true,
            animateExit: true,
            selectionMode: selectionMode,
            selectedTaskIds: selectedTaskIds,
            onTaskLongPress: onTaskLongPress,
            onTaskSelectionToggle: onTaskSelectionToggle,
          ),
        ],
      ),
    );
  }
}
