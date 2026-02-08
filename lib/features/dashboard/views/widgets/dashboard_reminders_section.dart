import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/features/dashboard/views/widgets/quick_reminder_card.dart';
import 'package:nexus/features/reminders/controllers/reminder_controller.dart';
import 'package:provider/provider.dart';

/// Dashboard section showing a grid of quick reminders.
class DashboardRemindersSection extends StatelessWidget {
  const DashboardRemindersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final reminderController = context.watch<ReminderController>();
    final reminders = reminderController.reminders;

    if (reminders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(
                Icons.alarm_off,
                size: 32,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No reminders',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final upcomingReminders = reminders.take(4).toList();
    return QuickRemindersGrid(
      reminders: upcomingReminders
          .map(
            (r) => QuickReminderData(
              timeLabel: DateFormat.jm().format(r.time),
              title: r.title,
              subtitle: 'Reminder',
              accentColor: Colors.orange,
            ),
          )
          .toList(),
    );
  }
}
