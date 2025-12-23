import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/features/reminders/controllers/reminder_controller.dart';
import 'package:nexus/features/reminders/models/reminder.dart';
import 'package:nexus/features/reminders/views/widgets/reminder_editor_dialog.dart';
import 'package:provider/provider.dart';

/// A list tile for displaying a reminder with actions.
class ReminderTile extends StatelessWidget {
  const ReminderTile({super.key, required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ReminderController>();
    final done = reminder.completedAt != null;

    return ListTile(
      leading: Icon(done ? Icons.check_circle : Icons.alarm),
      title: Text(reminder.title),
      subtitle: Text(DateFormat.yMMMd().add_Hm().format(reminder.time)),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          switch (v) {
            case 'edit':
              showReminderEditorDialog(context, reminder: reminder);
            case 'complete':
              controller.complete(reminder);
            case 'snooze':
              controller.snooze(reminder);
            case 'delete':
              controller.delete(reminder);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(value: 'complete', child: Text('Complete')),
          const PopupMenuItem(value: 'snooze', child: Text('Snooze 5m')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}
