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
          final isTitleValid = titleController.text.trim().isNotEmpty;
          final isTimeValid = selected.isAfter(DateTime.now());
          final canSave = isTitleValid && isTimeValid;

          return AlertDialog(
            title: Text(reminder == null ? 'Add reminder' : 'Edit reminder'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter reminder name',
                      ),
                      onChanged: (_) => setState(() {}),
                      autofocus: reminder == null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Quick set',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _QuickTimeChip(
                          label: '1 min',
                          onTap: () => setState(() {
                            selected = DateTime.now().add(
                              const Duration(minutes: 1),
                            );
                          }),
                        ),
                        _QuickTimeChip(
                          label: '5 min',
                          onTap: () => setState(() {
                            selected = DateTime.now().add(
                              const Duration(minutes: 5),
                            );
                          }),
                        ),
                        _QuickTimeChip(
                          label: '10 min',
                          onTap: () => setState(() {
                            selected = DateTime.now().add(
                              const Duration(minutes: 10),
                            );
                          }),
                        ),
                        _QuickTimeChip(
                          label: '15 min',
                          onTap: () => setState(() {
                            selected = DateTime.now().add(
                              const Duration(minutes: 15),
                            );
                          }),
                        ),
                        _QuickTimeChip(
                          label: '1 hour',
                          onTap: () => setState(() {
                            selected = DateTime.now().add(
                              const Duration(hours: 1),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Time'),
                      subtitle: Text(
                        DateFormat.jm().format(selected),
                        style: TextStyle(
                          color: isTimeValid ? null : Colors.red,
                        ),
                      ),
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
                    if (!isTimeValid)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Time must be in the future',
                          style: TextStyle(color: Colors.red, fontSize: 12),
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
                onPressed: canSave
                    ? () {
                        Navigator.of(dialogContext).pop(
                          ReminderEditorResult(
                            title: titleController.text,
                            time: selected,
                          ),
                        );
                      }
                    : null,
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

/// Quick time preset chip button.
class _QuickTimeChip extends StatelessWidget {
  const _QuickTimeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface),
    );
  }
}
