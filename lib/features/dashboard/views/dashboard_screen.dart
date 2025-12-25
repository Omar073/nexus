import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/theme_toggle_button.dart';
import 'package:nexus/features/dashboard/views/widgets/stat_card.dart';
import 'package:nexus/features/sync/views/sync_status_widget.dart';

/// Dashboard screen showing overview of tasks, reminders, notes, and habits.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Open menu',
        ),
        title: const Text('Dashboard'),
        actions: const [ThemeToggleButton(), SyncStatusWidget()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back!', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Here\'s your daily overview',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StatCard(
                icon: Icons.checklist,
                label: 'Tasks',
                value: '0',
                color: theme.colorScheme.primary,
              ),
              StatCard(
                icon: Icons.alarm,
                label: 'Reminders',
                value: '0',
                color: theme.colorScheme.secondary,
              ),
              StatCard(
                icon: Icons.note,
                label: 'Notes',
                value: '0',
                color: theme.colorScheme.tertiary,
              ),
              StatCard(
                icon: Icons.insights,
                label: 'Habits',
                value: '0',
                color: theme.colorScheme.error,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Today\'s Tasks', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No tasks for today',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
