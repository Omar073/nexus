import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/category_controller.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/views/widgets/sections/category_header.dart';
import 'package:nexus/features/tasks/views/widgets/sections/category_section_task_item.dart';
import 'package:nexus/features/tasks/views/widgets/sections/subcategory_section.dart';
import 'package:nexus/features/tasks/views/widgets/task_editor_dialog.dart';
import 'package:provider/provider.dart';

/// A section displaying tasks grouped under a category header.
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
  });

  final GlobalKey sectionKey;
  final String title;
  final List<Task> tasks;
  final TaskController taskController;
  final String? categoryId;
  final bool isCompletedTab;
  final bool animateExit;

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  /// Map of subcategory ID to expansion state
  final Map<String, bool> _subcategoryExpansion = {};

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
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
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

    // Group tasks by subcategory
    final rootTasks = <Task>[];
    final subcategoryTasks = <String, List<Task>>{};

    for (final task in widget.tasks) {
      if (task.subcategoryId == null) {
        rootTasks.add(task);
      } else {
        subcategoryTasks.putIfAbsent(task.subcategoryId!, () => []).add(task);
      }
    }

    // Sort subcategories by name
    final sortedSubIds = subcategoryTasks.keys.toList();
    sortedSubIds.sort((a, b) {
      final nameA = categoryController.getById(a)?.name ?? '';
      final nameB = categoryController.getById(b)?.name ?? '';
      return nameA.compareTo(nameB);
    });

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
              isExpanded: _isExpanded,
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
                      ),
                    ),
                    // Subcategories
                    ...sortedSubIds.map((subId) {
                      final tasks = subcategoryTasks[subId]!;
                      final subName =
                          categoryController.getById(subId)?.name ?? 'Unknown';
                      final isSubExpanded =
                          _subcategoryExpansion[subId] ?? true;

                      return SubcategorySection(
                        name: subName,
                        tasks: tasks,
                        taskController: widget.taskController,
                        subcategoryId: subId,
                        categoryId: widget.categoryId,
                        isExpanded: isSubExpanded,
                        onToggle: () {
                          setState(() {
                            _subcategoryExpansion[subId] = !isSubExpanded;
                          });
                        },
                        isCompletedTab: widget.isCompletedTab,
                        animateExit: widget.animateExit,
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
