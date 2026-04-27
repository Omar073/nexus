import 'package:flutter/material.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/task_editor/presentation/logic/task_editor_submission_logic.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/task_editor/presentation/utils/task_editor_actions.dart';
import 'package:nexus/features/task_editor/presentation/utils/task_editor_form_state.dart';
import 'package:nexus/features/task_editor/presentation/widgets/layout/task_editor_form_content.dart';
import 'package:nexus/features/task_editor/presentation/widgets/layout/task_editor_header.dart';
import 'package:nexus/features/task_editor/presentation/widgets/layout/task_editor_sheet_dismiss_wrapper.dart';
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
  late final TaskEditorFormState _formState;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _formState = TaskEditorFormState.fromTask(
      task: widget.task,
      initialCategoryId: widget.initialCategoryId,
      initialSubcategoryId: widget.initialSubcategoryId,
    );
    _debugLogExistingTaskSnapshot();
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

    return TaskEditorSheetDismissWrapper(
      onDismiss: () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
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
                onConfirm: _save,
              ),
              TaskEditorFormContent(
                mediaQuery: mediaQuery,
                isNewTask: widget.task == null,
                titleController: _titleController,
                descController: _descController,
                startDate: _formState.selectedStartDate,
                dueDate: _formState.selectedDueDate,
                dueTime: _formState.selectedDueTime,
                recurrence: _formState.selectedRecurrence,
                selectedCategoryId: _formState.selectedCategoryId,
                selectedSubcategoryId: _formState.selectedSubcategoryId,
                priority: _formState.selectedPriority,
                difficulty: _formState.selectedDifficulty,
                categoryController: categoryController,
                onPickStartDate: _pickStartDate,
                onPickDueDate: _pickDueDate,
                onPickDueTime: _pickDueTime,
                onPickRecurrence: _pickRecurrence,
                onCategoryChanged: (v) {
                  setState(() {
                    _formState.selectedCategoryId = v;
                    _formState.selectedSubcategoryId = null;
                  });
                },
                onSubcategoryChanged: (v) {
                  setState(() => _formState.selectedSubcategoryId = v);
                },
                onCreateNewCategory: () =>
                    _showCreateCategoryDialog(context, categoryController),
                onCreateNewSubcategory: () => _showCreateCategoryDialog(
                  context,
                  categoryController,
                  parentId: _formState.selectedCategoryId,
                ),
                onPriorityChanged: (v) =>
                    setState(() => _formState.selectedPriority = v),
                onDifficultyChanged: (v) =>
                    setState(() => _formState.selectedDifficulty = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateCategoryDialog(
    BuildContext context,
    CategoryController categoryController, {
    String? parentId,
  }) async {
    final categoryId = await showCreateTaskCategoryDialog(
      context: context,
      categoryController: categoryController,
      parentId: parentId,
    );
    if (categoryId != null) {
      setState(() {
        if (parentId != null) {
          _formState.selectedSubcategoryId = categoryId;
        } else {
          _formState.selectedCategoryId = categoryId;
          _formState.selectedSubcategoryId = null;
        }
      });
    }
  }

  void _pickStartDate() async {
    final date = await pickTaskStartDate(
      context,
      currentStartDate: _formState.selectedStartDate,
    );
    if (date != null) {
      setState(() => _formState.selectedStartDate = date);
    }
  }

  void _pickDueDate() async {
    final date = await pickTaskDueDate(
      context,
      currentDueDate: _formState.selectedDueDate,
    );
    if (date != null) {
      setState(() => _formState.selectedDueDate = date);
    }
  }

  void _pickDueTime() async {
    final time = await pickTaskTime(
      context,
      currentDueTime: _formState.selectedDueTime,
    );
    if (time != null) {
      setState(() => _formState.selectedDueTime = time);
    }
  }

  void _pickRecurrence() async {
    final result = await pickTaskRecurrenceRule(context);
    if (result != null) {
      setState(() => _formState.selectedRecurrence = result);
    }
  }

  void _debugLogExistingTaskSnapshot() {
    final task = widget.task;
    if (task == null) return;

    assert(() {
      debugPrint(
        '[DBG_TASK_SNAPSHOT] id=${task.id} title="${task.title}" desc="${task.description ?? ''}"',
      );
      return true;
    }());
  }

  void _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    await submitTaskEditorForm(
      controller: widget.controller,
      existingTask: widget.task,
      title: title,
      rawDescription: _descController.text,
      formState: _formState,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
