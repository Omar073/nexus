import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:nexus/features/tasks/views/task_editor/task_option_chip.dart';
import 'package:nexus/features/tasks/views/task_editor/task_priority_button.dart';

/// Main task editor sheet widget.
/// Displayed as a bottom sheet for creating or editing tasks.
class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({super.key, this.task, required this.controller});

  final Task? task;
  final TaskController controller;

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  TaskPriority? _selectedPriority;
  TaskDifficulty? _selectedDifficulty;
  TaskRecurrenceRule _selectedRecurrence = TaskRecurrenceRule.none;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedDueDate = widget.task?.dueDate;
    _selectedDueTime = widget.task?.dueDate != null
        ? TimeOfDay.fromDateTime(widget.task!.dueDate!)
        : null;
    _selectedPriority = widget.task?.priorityEnum;
    _selectedDifficulty = widget.task?.difficultyEnum;
    _selectedRecurrence =
        widget.task?.recurringRuleEnum ?? TaskRecurrenceRule.none;
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
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      margin: EdgeInsets.only(top: mediaQuery.padding.top + 40),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.task == null ? 'New Task' : 'Edit Task',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
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
                  // Title input
                  TextField(
                    controller: _titleController,
                    autofocus: widget.task == null,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What needs to be done?',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  TextField(
                    controller: _descController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Add details...',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Quick options row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Due date chip
                      TaskOptionChip(
                        icon: Icons.calendar_today,
                        label: _selectedDueDate != null
                            ? DateFormat('MMM d').format(_selectedDueDate!)
                            : 'Due date',
                        isSelected: _selectedDueDate != null,
                        onTap: _pickDueDate,
                      ),
                      // Due time chip
                      TaskOptionChip(
                        icon: Icons.schedule,
                        label: _selectedDueTime != null
                            ? _selectedDueTime!.format(context)
                            : 'Time',
                        isSelected: _selectedDueTime != null,
                        onTap: _pickDueTime,
                      ),
                      // Repeat chip
                      TaskOptionChip(
                        icon: Icons.repeat,
                        label: _getRecurrenceLabel(_selectedRecurrence),
                        isSelected:
                            _selectedRecurrence != TaskRecurrenceRule.none,
                        onTap: _pickRecurrence,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Priority selector
                  Text(
                    'Priority',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TaskPriorityButton(
                        label: 'Low',
                        color: Colors.green,
                        isSelected: _selectedPriority == TaskPriority.low,
                        onTap: () => setState(
                          () => _selectedPriority = TaskPriority.low,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TaskPriorityButton(
                        label: 'Medium',
                        color: Colors.orange,
                        isSelected: _selectedPriority == TaskPriority.medium,
                        onTap: () => setState(
                          () => _selectedPriority = TaskPriority.medium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TaskPriorityButton(
                        label: 'High',
                        color: Colors.red,
                        isSelected: _selectedPriority == TaskPriority.high,
                        onTap: () => setState(
                          () => _selectedPriority = TaskPriority.high,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Difficulty selector
                  Text(
                    'Difficulty',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TaskPriorityButton(
                        label: 'Easy',
                        color: Colors.teal,
                        isSelected: _selectedDifficulty == TaskDifficulty.low,
                        onTap: () => setState(
                          () => _selectedDifficulty = TaskDifficulty.low,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TaskPriorityButton(
                        label: 'Medium',
                        color: Colors.blue,
                        isSelected:
                            _selectedDifficulty == TaskDifficulty.medium,
                        onTap: () => setState(
                          () => _selectedDifficulty = TaskDifficulty.medium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TaskPriorityButton(
                        label: 'Hard',
                        color: Colors.purple,
                        isSelected: _selectedDifficulty == TaskDifficulty.high,
                        onTap: () => setState(
                          () => _selectedDifficulty = TaskDifficulty.high,
                        ),
                      ),
                    ],
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
    );
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

  String _getRecurrenceLabel(TaskRecurrenceRule rule) {
    switch (rule) {
      case TaskRecurrenceRule.daily:
        return 'Daily';
      case TaskRecurrenceRule.weekly:
        return 'Weekly';
      default:
        return 'Repeat';
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
        dueDate: dueDateTime,
        priority: _selectedPriority,
        difficulty: _selectedDifficulty,
        recurrence: _selectedRecurrence,
      );
    } else {
      await widget.controller.updateTask(
        widget.task!,
        title: title,
        description: _descController.text,
        dueDate: dueDateTime,
        priority: _selectedPriority,
        difficulty: _selectedDifficulty,
        recurrence: _selectedRecurrence,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
