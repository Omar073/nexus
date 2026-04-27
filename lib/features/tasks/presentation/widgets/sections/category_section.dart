import 'package:flutter/material.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/presentation/logic/category_section_logic.dart';
import 'package:nexus/features/tasks/presentation/state/category_section_state.dart';
import 'package:nexus/features/tasks/presentation/widgets/sections/category_header.dart';
import 'package:nexus/features/tasks/presentation/widgets/sections/category_section_task_item.dart';
import 'package:nexus/features/tasks/presentation/widgets/sections/subcategory_section.dart';
import 'package:nexus/features/task_editor/presentation/widgets/dialogs/task_editor_dialog.dart';
import 'package:provider/provider.dart';

/// Collapsible block of tasks under one category.
class CategorySection extends StatefulWidget {
  const CategorySection({
    super.key,
    required this.sectionKey,
    required this.title,
    required this.tasks,
    required this.taskController,
    this.categoryId,
    this.isCompletedTab = false,
    this.animateExit = false,
    this.selectionMode = false,
    this.selectedTaskIds = const <String>{},
    this.onTaskLongPress,
    this.onTaskSelectionToggle,
  });

  final GlobalKey sectionKey;
  final String title;
  final List<TaskEntity> tasks;
  final TaskController taskController;
  final String? categoryId;
  final bool isCompletedTab;
  final bool animateExit;
  final bool selectionMode;
  final Set<String> selectedTaskIds;
  final void Function(TaskEntity task)? onTaskLongPress;
  final void Function(TaskEntity task)? onTaskSelectionToggle;

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection>
    with SingleTickerProviderStateMixin {
  final CategorySectionState _sectionState = CategorySectionState();
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // Start expanded
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    _sectionState.toggleExpanded();
    setState(() {
      if (_sectionState.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _handleAddTask() {
    showTaskEditorDialog(context, categoryId: widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) return const SizedBox.shrink();

    final categoryController = context.watch<CategoryController>();

    final buckets = bucketTasksBySubcategory(widget.tasks);
    final rootTasks = buckets.rootTasks;
    final subcategoryTasks = buckets.bySubcategory;
    final sortedSubIds = sortSubcategoryIdsByName(
      subcategoryIds: subcategoryTasks.keys,
      resolveName: (id) => categoryController.getById(id)?.name ?? '',
    );

    return Container(
      key: widget.sectionKey,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(8),
            child: CategoryHeader(
              title: widget.title,
              taskCount: widget.tasks.length,
              isExpanded: _sectionState.isExpanded,
              onAddPressed: widget.categoryId != null ? _handleAddTask : null,
            ),
          ),

          // Synchronized horizontal slide + vertical height animation
          SizeTransition(
            sizeFactor: _animation,
            axisAlignment: -1.0,
            child: ClipRect(
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(-1.0, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // Root tasks
                    ...rootTasks.map(
                      (task) => CategorySectionTaskItem(
                        task: task,
                        taskController: widget.taskController,
                        isCompletedTab: widget.isCompletedTab,
                        animateExit: widget.animateExit,
                        selectionMode: widget.selectionMode,
                        isSelected: widget.selectedTaskIds.contains(task.id),
                        onSelectionToggle: widget.onTaskSelectionToggle == null
                            ? null
                            : () => widget.onTaskSelectionToggle!(task),
                        onLongPress: widget.onTaskLongPress == null
                            ? null
                            : () => widget.onTaskLongPress!(task),
                      ),
                    ),
                    // Subcategories
                    ...sortedSubIds.map((subId) {
                      final tasks = subcategoryTasks[subId]!;
                      final subName =
                          categoryController.getById(subId)?.name ?? 'Unknown';
                      final isSubExpanded = _sectionState.isSubExpanded(subId);

                      return SubcategorySection(
                        name: subName,
                        tasks: tasks,
                        taskController: widget.taskController,
                        subcategoryId: subId,
                        categoryId: widget.categoryId,
                        isExpanded: isSubExpanded,
                        onToggle: () {
                          setState(() {
                            _sectionState.toggleSubExpanded(subId);
                          });
                        },
                        isCompletedTab: widget.isCompletedTab,
                        animateExit: widget.animateExit,
                        selectionMode: widget.selectionMode,
                        selectedTaskIds: widget.selectedTaskIds,
                        onTaskLongPress: widget.onTaskLongPress,
                        onTaskSelectionToggle: widget.onTaskSelectionToggle,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
