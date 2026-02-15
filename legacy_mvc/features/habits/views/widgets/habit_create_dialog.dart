import 'package:flutter/material.dart';
import 'package:nexus/features/habits/controllers/habit_controller.dart';
import 'package:provider/provider.dart';

/// Shows a dialog for creating a new habit.
Future<void> showHabitCreateDialog(BuildContext context) async {
  final controller = context.read<HabitController>();
  final title = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('New habit'),
        content: TextField(
          controller: title,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(title.text),
            child: const Text('Create'),
          ),
        ],
      );
    },
  );
  if (result == null) return;
  if (result.trim().isEmpty) return;
  await controller.createHabit(title: result);
}
