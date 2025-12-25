import 'package:flutter/material.dart';
import 'package:nexus/features/analytics/controllers/analytics_controller.dart';
import 'package:nexus/features/analytics/utils/analytics_utils.dart';
import 'package:nexus/features/analytics/views/widgets/habits_progress_circle.dart';
import 'package:nexus/features/analytics/views/widgets/quick_stat_tile.dart';
import 'package:nexus/features/analytics/views/widgets/tasks_pie_chart.dart';
import 'package:nexus/features/dashboard/views/widgets/stat_card.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AnalyticsController>();
    final s = controller.snapshot;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overview Cards
          Text(
            'Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              StatCard(
                icon: Icons.checklist,
                label: 'Active Tasks',
                value: s.activeTasks.toString(),
                color: colorScheme.primary,
              ),
              StatCard(
                icon: Icons.check_circle,
                label: 'Completed',
                value: s.completedTasks.toString(),
                color: Colors.green,
              ),
              StatCard(
                icon: Icons.warning,
                label: 'Overdue',
                value: s.overdueTasks.toString(),
                color: Colors.orange,
              ),
              StatCard(
                icon: Icons.alarm,
                label: 'Reminders',
                value: s.upcomingReminders.toString(),
                color: colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tasks Status Pie Chart
          Text(
            'Tasks Status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: TasksPieChart(snapshot: s, colorScheme: colorScheme),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Habits Progress
          Text(
            'Habits Progress',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Progress',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${s.habitsDoneToday}/${s.totalHabits} habits',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      HabitsProgressCircle(
                        snapshot: s,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: s.totalHabits > 0
                          ? s.habitsDoneToday / s.totalHabits
                          : 0,
                      minHeight: 12,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        getProgressColor(s.habitsDoneToday, s.totalHabits),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Stats
          Text(
            'Quick Stats',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                QuickStatTile(
                  icon: Icons.trending_up,
                  label: 'Completion Rate',
                  value: getCompletionRate(s.completedTasks, s.activeTasks),
                  iconColor: Colors.green,
                ),
                const Divider(height: 1),
                QuickStatTile(
                  icon: Icons.schedule,
                  label: 'On-time Rate',
                  value: getOnTimeRate(s.overdueTasks, s.activeTasks),
                  iconColor: Colors.blue,
                ),
                const Divider(height: 1),
                QuickStatTile(
                  icon: Icons.insights,
                  label: 'Active Habits',
                  value: '${s.totalHabits} habits',
                  iconColor: Colors.purple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
