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
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      horizontalTitleGap: 8,
      leading: GestureDetector(
        onTap: () => controller.complete(reminder),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: done
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: 2,
            ),
            color: done ? theme.colorScheme.primary : Colors.transparent,
          ),
          child: done
              ? Icon(Icons.check, size: 18, color: theme.colorScheme.onPrimary)
              : null,
        ),
      ),
      title: Text(
        reminder.title,
        style: done
            ? TextStyle(
                decoration: TextDecoration.lineThrough,
                color: theme.colorScheme.outline,
              )
            : null,
      ),
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
