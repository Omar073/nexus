import 'package:flutter/material.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:nexus/features/tasks/presentation/extensions/task_entity_extensions.dart';
import 'package:nexus/features/task_editor/presentation/widgets/task_attribute_selectors.dart';
import 'package:nexus/features/task_editor/presentation/widgets/task_category_selector.dart';
import 'package:nexus/features/task_editor/presentation/widgets/task_editor_header.dart';
import 'package:nexus/features/task_editor/presentation/widgets/task_editor_inputs.dart';
import 'package:nexus/features/task_editor/presentation/widgets/task_quick_options.dart';
import 'package:provider/provider.dart';

/// Main task editor sheet widget.
/// Displayed as a bottom sheet for creating or editing tasks.
class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({
    super.key,
    this.task,
    required this.controller,
    this.initialCategoryId,
    this.initialSubcategoryId,
  });

  final TaskEntity? task;
  final TaskController controller;
  final String? initialCategoryId;
  final String? initialSubcategoryId;

  /// Wraps the editor with the app-level providers it depends on.
  ///
  /// This ensures that when pushed on the root navigator (outside the shell),
  /// the sheet has access to the task and category controllers.
  static Widget wrapWithRequiredProviders(
    BuildContext context, {
    required TaskEntity? task,
    String? categoryId,
    String? subcategoryId,
  }) {
    final taskController = context.read<TaskController>();
    final categoryController = context.read<CategoryController>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskController>.value(value: taskController),
        ChangeNotifierProvider<CategoryController>.value(
          value: categoryController,
        ),
      ],
      child: TaskEditorSheet(
        task: task,
        controller: taskController,
        initialCategoryId: categoryId,
        initialSubcategoryId: subcategoryId,
      ),
    );
  }

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  DateTime? _selectedStartDate;
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  TaskPriority? _selectedPriority;
  TaskDifficulty? _selectedDifficulty;
  TaskRecurrenceRule _selectedRecurrence = TaskRecurrenceRule.none;
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedStartDate = widget.task?.startDate;
    _selectedDueDate = widget.task?.dueDate;
    _selectedDueTime = widget.task?.dueDate != null
        ? TimeOfDay.fromDateTime(widget.task!.dueDate!)
        : null;
    _selectedPriority = widget.task?.priorityEnum;
    _selectedDifficulty = widget.task?.difficultyEnum;
    _selectedRecurrence =
        widget.task?.recurringRuleEnum ?? TaskRecurrenceRule.none;
    // Use initial values from props if provided, otherwise use task values
    _selectedCategoryId = widget.initialCategoryId ?? widget.task?.categoryId;
    _selectedSubcategoryId =
        widget.initialSubcategoryId ?? widget.task?.subcategoryId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final categoryController = context.watch<CategoryController>();

    return Container(
      margin: EdgeInsets.only(top: mediaQuery.padding.top + 40),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            TaskEditorHeader(
              isNewTask: widget.task == null,
              onClose: () => Navigator.of(context).pop(),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: mediaQuery.viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Inputs
                    TaskEditorInputs(
                      titleController: _titleController,
                      descController: _descController,
                      isNewTask: widget.task == null,
                    ),
                    const SizedBox(height: 24),
                    // Quick options row
                    TaskQuickOptions(
                      startDate: _selectedStartDate,
                      dueDate: _selectedDueDate,
                      dueTime: _selectedDueTime,
                      recurrence: _selectedRecurrence,
                      onPickStartDate: _pickStartDate,
                      onPickDueDate: _pickDueDate,
                      onPickDueTime: _pickDueTime,
                      onPickRecurrence: _pickRecurrence,
                    ),
                    const SizedBox(height: 24),
                    // Category selector
                    TaskCategorySelector(
                      categoryController: categoryController,
                      selectedCategoryId: _selectedCategoryId,
                      selectedSubcategoryId: _selectedSubcategoryId,
                      onCategoryChanged: (v) {
                        setState(() {
                          _selectedCategoryId = v;
                          _selectedSubcategoryId = null;
                        });
                      },
                      onSubcategoryChanged: (v) {
                        setState(() => _selectedSubcategoryId = v);
                      },
                      onCreateNewCategory: () => _showCreateCategoryDialog(
                        context,
                        categoryController,
                      ),
                      onCreateNewSubcategory: () => _showCreateCategoryDialog(
                        context,
                        categoryController,
                        parentId: _selectedCategoryId,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Attribute selectors (Priority & Difficulty)
                    TaskAttributeSelectors(
                      priority: _selectedPriority,
                      difficulty: _selectedDifficulty,
                      onPriorityChanged: (v) =>
                          setState(() => _selectedPriority = v),
                      onDifficultyChanged: (v) =>
                          setState(() => _selectedDifficulty = v),
                    ),
                    const SizedBox(height: 32),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.task == null ? 'Create Task' : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///todo: extract following code to a separate file
  void _showCreateCategoryDialog(
    BuildContext context,
    CategoryController categoryController, {
    String? parentId,
  }) async {
    final controller = TextEditingController();
    final isSubcategory = parentId != null;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSubcategory ? 'New Subcategory' : 'New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isSubcategory ? 'Subcategory name' : 'Category name',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final category = await categoryController.createCategory(
        result,
        parentId: parentId,
      );
      setState(() {
        if (isSubcategory) {
          _selectedSubcategoryId = category.id;
        } else {
          _selectedCategoryId = category.id;
          _selectedSubcategoryId = null;
        }
      });
    }
  }

  void _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      if (_selectedDueDate != null && date.isAfter(_selectedDueDate!)) {
        // If start date is after due date, clear due date or adjust logic?
        // User asked for "start date x, end date y".
        // For now, let's just set it. Validation can be added if requested.
      }
      setState(() => _selectedStartDate = date);
    }
  }

  void _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _selectedDueDate = date);
    }
  }

  void _pickDueTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedDueTime = time);
    }
  }

  void _pickRecurrence() async {
    final result = await showModalBottomSheet<TaskRecurrenceRule>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('No repeat'),
            leading: const Icon(Icons.close),
            onTap: () => Navigator.pop(context, TaskRecurrenceRule.none),
          ),
          ListTile(
            title: const Text('Daily'),
            leading: const Icon(Icons.repeat),
            onTap: () => Navigator.pop(context, TaskRecurrenceRule.daily),
          ),
          ListTile(
            title: const Text('Weekly'),
            leading: const Icon(Icons.repeat),
            onTap: () => Navigator.pop(context, TaskRecurrenceRule.weekly),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
    if (result != null) {
      setState(() => _selectedRecurrence = result);
    }
  }

  void _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    // Combine date and time
    DateTime? dueDateTime;
    if (_selectedDueDate != null) {
      dueDateTime = DateTime(
        _selectedDueDate!.year,
        _selectedDueDate!.month,
        _selectedDueDate!.day,
        _selectedDueTime?.hour ?? 0,
        _selectedDueTime?.minute ?? 0,
      );
    }

    if (widget.task == null) {
      await widget.controller.createTask(
        title: title,
        description: _descController.text,
        startDate: _selectedStartDate,
        dueDate: dueDateTime,
        priority: _selectedPriority,
        difficulty: _selectedDifficulty,
        recurrence: _selectedRecurrence,
        categoryId: _selectedCategoryId,
        subcategoryId: _selectedSubcategoryId,
      );
    } else {
      await widget.controller.updateTask(
        widget.task!,
        title: title,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text,
        startDate: _selectedStartDate,
        dueDate: dueDateTime,
        priority: _selectedPriority,
        difficulty: _selectedDifficulty,
        recurrence: _selectedRecurrence,
        categoryId: _selectedCategoryId,
        subcategoryId: _selectedSubcategoryId,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
