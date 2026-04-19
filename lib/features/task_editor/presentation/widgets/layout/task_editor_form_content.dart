import 'package:flutter/material.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:nexus/features/task_editor/presentation/widgets/options/task_attribute_selectors.dart';
import 'package:nexus/features/task_editor/presentation/widgets/options/task_category_selector.dart';
import 'package:nexus/features/task_editor/presentation/widgets/options/task_quick_options.dart';
import 'package:nexus/features/task_editor/presentation/widgets/inputs/task_editor_inputs.dart';

class TaskEditorFormContent extends StatelessWidget {
  const TaskEditorFormContent({
    super.key,
    required this.mediaQuery,
    required this.isNewTask,
    required this.titleController,
    required this.descController,
    required this.startDate,
    required this.dueDate,
    required this.dueTime,
    required this.recurrence,
    required this.selectedCategoryId,
    required this.selectedSubcategoryId,
    required this.priority,
    required this.difficulty,
    required this.categoryController,
    required this.onPickStartDate,
    required this.onPickDueDate,
    required this.onPickDueTime,
    required this.onPickRecurrence,
    required this.onCategoryChanged,
    required this.onSubcategoryChanged,
    required this.onCreateNewCategory,
    required this.onCreateNewSubcategory,
    required this.onPriorityChanged,
    required this.onDifficultyChanged,
    required this.onSave,
  });
  // todo: we should extract this as a new class?

  final MediaQueryData mediaQuery;
  final bool isNewTask;
  final TextEditingController titleController;
  final TextEditingController descController;
  final DateTime? startDate;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
  final TaskRecurrenceRule recurrence;
  final String? selectedCategoryId;
  final String? selectedSubcategoryId;
  final TaskPriority? priority;
  final TaskDifficulty? difficulty;
  final CategoryController categoryController;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickDueDate;
  final VoidCallback onPickDueTime;
  final VoidCallback onPickRecurrence;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onSubcategoryChanged;
  final VoidCallback onCreateNewCategory;
  final VoidCallback onCreateNewSubcategory;
  final ValueChanged<TaskPriority?> onPriorityChanged;
  final ValueChanged<TaskDifficulty?> onDifficultyChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: mediaQuery.viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskEditorInputs(
              titleController: titleController,
              descController: descController,
              isNewTask: isNewTask,
            ),
            const SizedBox(height: 24),
            TaskQuickOptions(
              startDate: startDate,
              dueDate: dueDate,
              dueTime: dueTime,
              recurrence: recurrence,
              onPickStartDate: onPickStartDate,
              onPickDueDate: onPickDueDate,
              onPickDueTime: onPickDueTime,
              onPickRecurrence: onPickRecurrence,
            ),
            const SizedBox(height: 24),
            TaskCategorySelector(
              categoryController: categoryController,
              selectedCategoryId: selectedCategoryId,
              selectedSubcategoryId: selectedSubcategoryId,
              onCategoryChanged: onCategoryChanged,
              onSubcategoryChanged: onSubcategoryChanged,
              onCreateNewCategory: onCreateNewCategory,
              onCreateNewSubcategory: onCreateNewSubcategory,
            ),
            const SizedBox(height: 24),
            TaskAttributeSelectors(
              priority: priority,
              difficulty: difficulty,
              onPriorityChanged: onPriorityChanged,
              onDifficultyChanged: onDifficultyChanged,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isNewTask ? 'Create Task' : 'Save Changes',
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
    );
  }
}
