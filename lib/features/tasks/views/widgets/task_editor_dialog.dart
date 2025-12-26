import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_editor_result.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:provider/provider.dart';

/// Shows a dialog for creating or editing a task.
///
/// Returns void, handling the task creation/update internally.
Future<void> showTaskEditorDialog(BuildContext context, {Task? task}) async {
  final controller = context.read<TaskController>();
  final titleController = TextEditingController(text: task?.title ?? '');
  final descController = TextEditingController(text: task?.description ?? '');

  // Initial values from existing task or defaults
  DateTime? selectedDueDate = task?.dueDate;
  TaskPriority? selectedPriority = task?.priorityEnum;
  TaskDifficulty? selectedDifficulty = task?.difficultyEnum;
  TaskRecurrenceRule selectedRecurrence =
      task?.recurringRuleEnum ?? TaskRecurrenceRule.none;

  final result = await showDialog<TaskEditorResult>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(task == null ? 'Add task' : 'Edit task'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    TextField(
                      controller: titleController,
                      autofocus: task == null,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextField(
                      controller: descController,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Due Date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        selectedDueDate != null
                            ? '${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}'
                            : 'No due date',
                      ),
                      subtitle: const Text('Due Date'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selectedDueDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => selectedDueDate = null),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_calendar),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: dialogContext,
                                initialDate: selectedDueDate ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365 * 5),
                                ),
                              );
                              if (date != null) {
                                setState(() => selectedDueDate = date);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // Priority
                    DropdownButtonFormField<TaskPriority?>(
                      key: ValueKey('priority_$selectedPriority'),
                      initialValue: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('None')),
                        DropdownMenuItem(
                          value: TaskPriority.low,
                          child: Text('Low'),
                        ),
                        DropdownMenuItem(
                          value: TaskPriority.medium,
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(
                          value: TaskPriority.high,
                          child: Text('High'),
                        ),
                      ],
                      onChanged: (v) => setState(() => selectedPriority = v),
                    ),
                    const SizedBox(height: 16),

                    // Difficulty
                    DropdownButtonFormField<TaskDifficulty?>(
                      key: ValueKey('difficulty_$selectedDifficulty'),
                      initialValue: selectedDifficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.speed),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('None')),
                        DropdownMenuItem(
                          value: TaskDifficulty.low,
                          child: Text('Easy'),
                        ),
                        DropdownMenuItem(
                          value: TaskDifficulty.medium,
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(
                          value: TaskDifficulty.high,
                          child: Text('Hard'),
                        ),
                      ],
                      onChanged: (v) => setState(() => selectedDifficulty = v),
                    ),
                    const SizedBox(height: 16),

                    // Recurrence
                    DropdownButtonFormField<TaskRecurrenceRule>(
                      key: ValueKey('recurrence_$selectedRecurrence'),
                      initialValue: selectedRecurrence,
                      decoration: const InputDecoration(
                        labelText: 'Repeat',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TaskRecurrenceRule.none,
                          child: Text('No repeat'),
                        ),
                        DropdownMenuItem(
                          value: TaskRecurrenceRule.daily,
                          child: Text('Daily'),
                        ),
                        DropdownMenuItem(
                          value: TaskRecurrenceRule.weekly,
                          child: Text('Weekly'),
                        ),
                      ],
                      onChanged: (v) => setState(
                        () => selectedRecurrence = v ?? TaskRecurrenceRule.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    TaskEditorResult(
                      title: titleController.text,
                      description: descController.text,
                      dueDate: selectedDueDate,
                      priority: selectedPriority,
                      difficulty: selectedDifficulty,
                      recurrence: selectedRecurrence,
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result == null) return;
  if (result.title.trim().isEmpty) return;

  if (task == null) {
    await controller.createTask(
      title: result.title,
      description: result.description,
      dueDate: result.dueDate,
      priority: result.priority,
      difficulty: result.difficulty,
      recurrence: result.recurrence,
    );
  } else {
    await controller.updateTask(
      task,
      title: result.title,
      description: result.description,
      dueDate: result.dueDate,
      priority: result.priority,
      difficulty: result.difficulty,
      recurrence: result.recurrence,
    );
  }
}
