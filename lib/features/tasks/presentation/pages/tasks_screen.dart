import 'package:flutter/material.dart';
import 'package:nexus/features/categories/data/models/category.dart';
import 'package:nexus/features/categories/domain/category_sort_option.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/categories/presentation/widgets/category_drawer.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/presentation/state/task_selection_state.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/presentation/utils/task_bulk_actions.dart';
import 'package:nexus/features/tasks/presentation/widgets/helpers/category_scroll_helper.dart';
import 'package:nexus/features/tasks/presentation/widgets/sections/task_selection_bar.dart';
import 'package:nexus/features/tasks/presentation/widgets/sections/tasks_tab_body.dart';
import 'package:nexus/features/task_editor/presentation/widgets/dialogs/task_editor_dialog.dart';
import 'package:provider/provider.dart';

/// Tabbed task views with categories and bulk actions.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CategoryScrollHelper _scrollHelper;
  final TaskSelectionState _selectionState = TaskSelectionState();

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

  void _enterTaskSelection(TaskEntity task) {
    _selectionState.enter(task.id);
    setState(() {});
  }

  void _toggleTaskSelection(TaskEntity task) {
    _selectionState.toggle(task.id);
    setState(() {});
  }

  void _clearTaskSelection() {
    _selectionState.clear();
    setState(() {});
  }

  void _showCategoryDrawer(
    Map<String?, int> taskCounts,
    List<Category> sortedCategories,
  ) {
    final taskController = context.read<TaskController>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.6,
        minChildSize: 0.25,
        builder: (context, scrollController) => CategoryDrawer(
          scrollController: scrollController,
          onCategorySelected: (categoryId) =>
              _scrollHelper.scrollToCategory(categoryId, mounted: mounted),
          taskCountByCategory: taskCounts,
          sortedCategories: sortedCategories,
          onClearTasks: taskController.clearCategoryOnTasks,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskController = context.watch<TaskController>();
    final categoryController = context.watch<CategoryController>();
    final navBarStyle = context.watch<SettingsController>().navBarStyle;

    final categorySort = context.select<SettingsController, CategorySortOption>(
      (s) => s.categorySortOption,
    );

    final pendingTasks = [
      ...taskController.tasksForStatus(TaskStatus.active),
      ...taskController.tasksForStatus(TaskStatus.pending),
    ];
    final completedTasks = taskController.tasksForStatus(TaskStatus.completed);
    final allTasks = [...pendingTasks, ...completedTasks];

    final categories = categoryController.getSortedCategories(
      sortOption: categorySort,
      sortableItems: allTasks,
    );
    final categoryIdToRootId = <String, String>{};
    for (final c in categoryController.allCategories) {
      categoryIdToRootId[c.id] = c.parentId ?? c.id;
    }

    final selectionMode = _selectionState.selectionMode;
    final selectedIds = _selectionState.selectedIds;

    return Scaffold(
      body: SafeArea(
        child: TasksTabBody(
          tabController: _tabController,
          pendingTasks: pendingTasks,
          completedTasks: completedTasks,
          categories: categories,
          categoryIdToRootId: categoryIdToRootId,
          taskController: taskController,
          categoryKeys: _categoryKeys,
          onShowDrawer: _showCategoryDrawer,
          selectionMode: selectionMode,
          selectedTaskIds: selectedIds,
          onTaskLongPress: _enterTaskSelection,
          onTaskSelectionToggle: _toggleTaskSelection,
        ),
      ),
      floatingActionButton: selectionMode
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: navBarStyle.fabOffset(context)),
              child: FloatingActionButton(
                heroTag: 'tasks_fab',
                onPressed: () => showTaskEditorDialog(context),
                child: const Icon(Icons.add),
              ),
            ),
      bottomNavigationBar: selectionMode
          ? TaskSelectionBar(
              selectedCount: selectedIds.length,
              onSelectAll: () {
                final tasksForTab = switch (_tabController.index) {
                  0 => pendingTasks,
                  1 => allTasks,
                  2 => completedTasks,
                  _ => allTasks,
                };
                _selectionState.selectAll(tasksForTab);
                setState(() {});
              },
              onExitSelection: _clearTaskSelection,
              onToggleComplete: () =>
                  TaskBulkActions.toggleCompletedForSelected(
                    controller: taskController,
                    selectedIds: selectedIds.toList(),
                    onCleared: _clearTaskSelection,
                  ),
              onMoveCategory: () => TaskBulkActions.moveSelectedToCategory(
                context: context,
                controller: taskController,
                selectedIds: selectedIds.toList(),
                categories: categories,
                onCleared: _clearTaskSelection,
              ),
              onDelete: () => TaskBulkActions.deleteSelected(
                context: context,
                controller: taskController,
                selectedIds: selectedIds.toList(),
                onCleared: _clearTaskSelection,
              ),
            )
          : null,
    );
  }
}
