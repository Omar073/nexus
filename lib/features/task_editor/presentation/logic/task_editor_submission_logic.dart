import 'package:nexus/features/task_editor/presentation/utils/task_editor_form_state.dart';
import 'package:nexus/features/task_editor/presentation/utils/task_editor_save_utils.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';

Future<void> submitTaskEditorForm({
  required TaskController controller,
  required TaskEntity? existingTask,
  required String title,
  required String rawDescription,
  required TaskEditorFormState formState,
}) async {
  final dueDateTime = buildDueDateTime(
    formState.selectedDueDate,
    formState.selectedDueTime,
  );

  if (existingTask == null) {
    await controller.createTask(
      title: title,
      description: rawDescription,
      startDate: formState.selectedStartDate,
      dueDate: dueDateTime,
      priority: formState.selectedPriority,
      difficulty: formState.selectedDifficulty,
      recurrence: formState.selectedRecurrence,
      categoryId: formState.selectedCategoryId,
      subcategoryId: formState.selectedSubcategoryId,
    );
    return;
  }

  await controller.updateTask(
    existingTask,
    title: title,
    description: optionalDescription(rawDescription),
    startDate: formState.selectedStartDate,
    dueDate: dueDateTime,
    priority: formState.selectedPriority,
    difficulty: formState.selectedDifficulty,
    recurrence: formState.selectedRecurrence,
    categoryId: formState.selectedCategoryId,
    subcategoryId: formState.selectedSubcategoryId,
  );
}
