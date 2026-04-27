import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:nexus/features/tasks/presentation/extensions/task_entity_extensions.dart';

/// Mutable form state for the task editor sheet.
class TaskEditorFormState {
  TaskEditorFormState({
    this.selectedStartDate,
    this.selectedDueDate,
    this.selectedDueTime,
    this.selectedPriority,
    this.selectedDifficulty,
    required this.selectedRecurrence,
    this.selectedCategoryId,
    this.selectedSubcategoryId,
  });

  factory TaskEditorFormState.fromTask({
    required TaskEntity? task,
    String? initialCategoryId,
    String? initialSubcategoryId,
  }) {
    return TaskEditorFormState(
      selectedStartDate: task?.startDate,
      selectedDueDate: task?.dueDate,
      selectedDueTime: task?.dueDate != null
          ? TimeOfDay.fromDateTime(task!.dueDate!)
          : null,
      selectedPriority: task?.priorityEnum,
      selectedDifficulty: task?.difficultyEnum,
      selectedRecurrence: task?.recurringRuleEnum ?? TaskRecurrenceRule.none,
      selectedCategoryId: initialCategoryId ?? task?.categoryId,
      selectedSubcategoryId: initialSubcategoryId ?? task?.subcategoryId,
    );
  }

  DateTime? selectedStartDate;
  DateTime? selectedDueDate;
  TimeOfDay? selectedDueTime;
  TaskPriority? selectedPriority;
  TaskDifficulty? selectedDifficulty;
  TaskRecurrenceRule selectedRecurrence;
  String? selectedCategoryId;
  String? selectedSubcategoryId;
}
