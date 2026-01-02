import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/features/reminders/controllers/reminder_controller.dart';
import 'package:nexus/features/reminders/models/reminder.dart';
import 'package:provider/provider.dart';

/// Result class for the reminder editor dialog.
class ReminderEditorResult {
  ReminderEditorResult({required this.title, required this.time});
  final String title;
  final DateTime time;
}

/// Shows a dialog for creating or editing a reminder.
Future<void> showReminderEditorDialog(
  BuildContext context, {
  Reminder? reminder,
}) async {
  final controller = context.read<ReminderController>();
  final titleController = TextEditingController(text: reminder?.title ?? '');
  DateTime selected =
      reminder?.time ?? DateTime.now().add(const Duration(minutes: 5));

  final result = await showDialog<ReminderEditorResult>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(reminder == null ? 'Add reminder' : 'Edit reminder'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Time'),
                    subtitle: Text(DateFormat.jm().format(selected)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () async {
                      if (!dialogContext.mounted) return;
                      final time = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay.fromDateTime(selected),
                      );
                      if (time == null) return;
                      final now = DateTime.now();
                      setState(() {
                        // Always set to today, preserving the selected time
                        selected = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                  ),
                ],
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
                    ReminderEditorResult(
                      title: titleController.text,
                      time: selected,
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

  if (reminder == null) {
    await controller.create(title: result.title, time: result.time);
  } else {
    await controller.update(reminder, title: result.title, time: result.time);
  }
}
