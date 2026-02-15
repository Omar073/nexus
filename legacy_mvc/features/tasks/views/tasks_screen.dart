import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/category_controller.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';

import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/settings/models/nav_bar_style.dart';
import 'package:nexus/features/tasks/models/category.dart';
import 'package:nexus/features/tasks/models/category_sort_option.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:nexus/features/tasks/views/widgets/helpers/category_scroll_helper.dart';
import 'package:nexus/features/tasks/views/widgets/helpers/sliver_tab_bar_delegate.dart';
import 'package:nexus/features/tasks/views/widgets/lists/grouped_task_list.dart';
import 'package:nexus/features/tasks/views/widgets/navigation/category_drawer.dart';

import 'package:nexus/features/tasks/views/widgets/sections/tasks_header.dart';
import 'package:nexus/features/tasks/views/widgets/task_editor_dialog.dart';
import 'package:provider/provider.dart';

/// Main tasks screen with tab-based filtering and category grouping.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CategoryScrollHelper _scrollHelper;

  // Keys for each category section (keyed by "tabIndex:categoryId")
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollHelper = CategoryScrollHelper(
      categoryKeys: _categoryKeys,
      getCurrentTabIndex: () => _tabController.index,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCategoryDrawer(
    Map<String?, int> taskCounts,
    List<Category> sortedCategories,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryDrawer(
        onCategorySelected: (categoryId) =>
            _scrollHelper.scrollToCategory(categoryId, mounted: mounted),
        taskCountByCategory: taskCounts,
        sortedCategories: sortedCategories,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskController = context.watch<TaskController>();
    final categoryController = context.watch<CategoryController>();
    final navBarStyle = context.watch<SettingsController>().navBarStyle;

    final categorySort = context.select<SettingsController, CategorySortOption>(
      (s) => s.categorySortOption,
    );

    // Get tasks for each tab
    final pendingTasks = [
      ...taskController.tasksForStatus(TaskStatus.active),
      ...taskController.tasksForStatus(TaskStatus.pending),
    ];
    final completedTasks = taskController.tasksForStatus(TaskStatus.completed);
    final allTasks = [...pendingTasks, ...completedTasks];

    // Get sorted categories from controller
    final categories = categoryController.getSortedCategories(
      sortOption: categorySort,
      tasks: allTasks,
    );

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Header section - scrolls away
            const SliverToBoxAdapter(child: TasksHeader()),
            // TabBar - pinned
            SliverPersistentHeader(
              pinned: true,
              delegate: SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
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
            controller: _tabController,
            children: [
              GroupedTaskList(
                tabIndex: 0,
                tasks: pendingTasks,
                categories: categories,
                taskController: taskController,
                categoryKeys: _categoryKeys,
                onShowDrawer: _showCategoryDrawer,
                emptyMessage: 'No pending tasks',
                emptyIcon: Icons.check_circle_outline,
                animateExit: true,
              ),
              GroupedTaskList(
                tabIndex: 1,
                tasks: allTasks,
                categories: categories,
                taskController: taskController,
                categoryKeys: _categoryKeys,
                onShowDrawer: _showCategoryDrawer,
                emptyMessage: 'No tasks yet',
                emptyIcon: Icons.task_alt,
              ),
              GroupedTaskList(
                tabIndex: 2,
                tasks: completedTasks,
                categories: categories,
                taskController: taskController,
                categoryKeys: _categoryKeys,
                onShowDrawer: _showCategoryDrawer,
                emptyMessage: 'No completed tasks',
                emptyIcon: Icons.done_all,
                isCompletedTab: true,
                animateExit: true,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: navBarStyle.fabOffset),
        child: FloatingActionButton(
          heroTag: 'tasks_fab',
          onPressed: () => showTaskEditorDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
