import 'package:flutter/material.dart';
import 'package:nexus/features/reminders/controllers/reminder_controller.dart';
import 'package:nexus/features/reminders/views/widgets/reminder_editor_dialog.dart';
import 'package:nexus/features/reminders/views/widgets/reminder_tile.dart';
import 'package:nexus/features/wrapper/views/app_wrapper.dart';
import 'package:provider/provider.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<ReminderController>();
    final allReminders = controller.reminders;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter reminders: Only show past incomplete ones and today's reminders
    final displayReminders = allReminders.where((r) {
      final rDate = DateTime(r.time.year, r.time.month, r.time.day);
      if (rDate.isBefore(today) && r.completedAt == null) {
        return true; // Overdue
      }
      if (rDate.isAtSameMomentAs(today)) return true; // Today
      return false; // Future or others
    }).toList();

    // Sort: Overdue first, then by time
    displayReminders.sort((a, b) => a.time.compareTo(b.time));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () =>
                  AppWrapper.scaffoldKey.currentState?.openDrawer(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Reminders',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (displayReminders.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No reminders for today',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ReminderTile(reminder: displayReminders[index]),
                  );
                }, childCount: displayReminders.length),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'reminders_fab',
        onPressed: () => showReminderEditorDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
