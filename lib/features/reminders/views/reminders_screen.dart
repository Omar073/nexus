import 'package:flutter/material.dart';
import 'package:nexus/features/reminders/controllers/reminder_controller.dart';
import 'package:nexus/features/reminders/views/widgets/reminder_editor_dialog.dart';
import 'package:nexus/features/reminders/views/widgets/reminder_tile.dart';
import 'package:provider/provider.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReminderController>();
    final reminders = controller.reminders;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: reminders.isEmpty
          ? const Center(child: Text('No reminders'))
          : ListView.separated(
              itemCount: reminders.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final r = reminders[index];
                return ReminderTile(reminder: r);
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'reminders_fab',
        onPressed: () => showReminderEditorDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
