import 'package:flutter/material.dart';

/// Title and notes text fields for a task.
class TaskEditorInputs extends StatelessWidget {
  const TaskEditorInputs({
    super.key,
    required this.titleController,
    required this.descController,
    required this.isNewTask,
  });

  final TextEditingController titleController;
  final TextEditingController descController;
  final bool isNewTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: titleController,
          autofocus: isNewTask,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'What needs to be done?',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
        TextField(
          controller: descController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add details...',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
      ],
    );
  }
}
