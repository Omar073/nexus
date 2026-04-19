import 'package:flutter/material.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:nexus/features/tasks/presentation/extensions/task_entity_extensions.dart';
import 'package:nexus/features/task_editor/presentation/utils/task_editor_pickers.dart';
import 'package:nexus/features/task_editor/presentation/utils/task_editor_save_utils.dart';
import 'package:nexus/features/task_editor/presentation/widgets/dialogs/task_category_name_dialog.dart';
import 'package:nexus/features/task_editor/presentation/widgets/layout/task_editor_form_content.dart';
import 'package:nexus/features/task_editor/presentation/widgets/layout/task_editor_header.dart';
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
            TaskEditorFormContent(
              mediaQuery: mediaQuery,
              isNewTask: widget.task == null,
              titleController: _titleController,
              descController: _descController,
              startDate: _selectedStartDate,
              dueDate: _selectedDueDate,
              dueTime: _selectedDueTime,
              recurrence: _selectedRecurrence,
              selectedCategoryId: _selectedCategoryId,
              selectedSubcategoryId: _selectedSubcategoryId,
              priority: _selectedPriority,
              difficulty: _selectedDifficulty,
              categoryController: categoryController,
              onPickStartDate: _pickStartDate,
              onPickDueDate: _pickDueDate,
              onPickDueTime: _pickDueTime,
              onPickRecurrence: _pickRecurrence,
              onCategoryChanged: (v) {
                setState(() {
                  _selectedCategoryId = v;
                  _selectedSubcategoryId = null;
                });
              },
              onSubcategoryChanged: (v) {
                setState(() => _selectedSubcategoryId = v);
              },
              onCreateNewCategory: () =>
                  _showCreateCategoryDialog(context, categoryController),
              onCreateNewSubcategory: () => _showCreateCategoryDialog(
                context,
                categoryController,
                parentId: _selectedCategoryId,
              ),
              onPriorityChanged: (v) => setState(() => _selectedPriority = v),
              onDifficultyChanged: (v) =>
                  setState(() => _selectedDifficulty = v),
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCategoryDialog(
    BuildContext context,
    CategoryController categoryController, {
    String? parentId,
  }) async {
    final isSubcategory = parentId != null;
    final result = await showTaskCategoryNameDialog(
      context,
      isSubcategory: isSubcategory,
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
    final date = await pickTaskDate(
      context,
      initialDate: _selectedStartDate ?? DateTime.now(),
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
    final date = await pickTaskDate(
      context,
      initialDate: _selectedDueDate ?? DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDueDate = date);
    }
  }

  void _pickDueTime() async {
    final time = await pickTaskDueTime(
      context,
      initialTime: _selectedDueTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedDueTime = time);
    }
  }

  void _pickRecurrence() async {
    final result = await pickTaskRecurrence(context);
    if (result != null) {
      setState(() => _selectedRecurrence = result);
    }
  }

  void _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final dueDateTime = buildDueDateTime(_selectedDueDate, _selectedDueTime);

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
        description: optionalDescription(_descController.text),
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
