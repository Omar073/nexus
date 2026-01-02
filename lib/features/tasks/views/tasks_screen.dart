import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/category_controller.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';

import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/tasks/models/category_sort_option.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:nexus/features/tasks/views/widgets/helpers/sliver_tab_bar_delegate.dart';
import 'package:nexus/features/tasks/views/widgets/lists/grouped_task_list.dart';
import 'package:nexus/features/tasks/views/widgets/navigation/category_drawer.dart';

import 'package:nexus/features/tasks/views/widgets/sections/tasks_header.dart';
import 'package:nexus/features/wrapper/views/nav_bar_wrappers/curved_nav_bar.dart';
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

  // Keys for each category section (keyed by "tabIndex:categoryId")
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _scrollToCategory(String? categoryId) {
    final keyStr = '${_tabController.index}:$categoryId';
    final key = _categoryKeys[keyStr];

    // Use post-frame callback to ensure scroll happens after bottom sheet closes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (key?.currentContext != null && mounted) {
          final targetContext = key!.currentContext!;

          // Find the scrollable ancestor and its context
          final scrollable = Scrollable.maybeOf(targetContext);
          if (scrollable != null) {
            final scrollPosition = scrollable.position;

            // Get the target render object
            final targetRenderObject =
                targetContext.findRenderObject() as RenderBox?;
            if (targetRenderObject == null) return;

            // Get the scrollable render object
            final scrollableRenderObject =
                scrollable.context.findRenderObject() as RenderBox?;
            if (scrollableRenderObject == null) return;

            // Calculate the target's position relative to the scrollable viewport
            final targetOffset = targetRenderObject.localToGlobal(
              Offset.zero,
              ancestor: scrollableRenderObject,
            );

            // Calculate the new scroll offset
            // Subtract offset to keep the full category header visible
            final currentOffset = scrollPosition.pixels;
            final headerOffset =
                48.0; // Enough space to show full category header
            final targetScrollOffset =
                currentOffset + targetOffset.dy - headerOffset;

            // Clamp to valid scroll range
            final clampedOffset = targetScrollOffset.clamp(
              scrollPosition.minScrollExtent,
              scrollPosition.maxScrollExtent,
            );

            // Animate to the target position
            // ignore: unawaited_futures
            scrollPosition.animateTo(
              clampedOffset,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    });
  }

  void _showCategoryDrawer(Map<String?, int> taskCounts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryDrawer(
        onCategorySelected: _scrollToCategory,
        taskCountByCategory: taskCounts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskController = context.watch<TaskController>();
    final categoryController = context.watch<CategoryController>();

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

    // Sort categories
    var categories = categoryController.rootCategories;
    if (categorySort != CategorySortOption.defaultOrder) {
      categories = List.of(categories); // Create copy to sort
      switch (categorySort) {
        case CategorySortOption.defaultOrder:
          break; // Already insertion order
        case CategorySortOption.alphabeticalAsc:
          categories.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        case CategorySortOption.alphabeticalDesc:
          categories.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          );
        case CategorySortOption.recentlyModified:
          // Calculate max updated time for each category
          final lastUpdates = <String, DateTime>{};
          for (final task in allTasks) {
            if (task.categoryId != null) {
              final updated = task.updatedAt;
              final time = updated;
              final current = lastUpdates[task.categoryId!];
              if (current == null || time.isAfter(current)) {
                lastUpdates[task.categoryId!] = time;
              }
            }
          }
          categories.sort((a, b) {
            final timeA =
                lastUpdates[a.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
            final timeB =
                lastUpdates[b.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
            return timeB.compareTo(timeA); // Descending (newest first)
          });
      }
    }

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
        padding: const EdgeInsets.only(bottom: CurvedNavBarWrapper.height + 50),
        child: FloatingActionButton(
          heroTag: 'tasks_fab',
          onPressed: () => showTaskEditorDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
