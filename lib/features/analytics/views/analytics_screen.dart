import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nexus/core/extensions/l10n_x.dart';
import 'package:nexus/features/analytics/controllers/analytics_controller.dart';
import 'package:nexus/features/analytics/views/widgets/legend_item.dart';
import 'package:nexus/features/analytics/views/widgets/quick_stat_tile.dart';
import 'package:nexus/features/dashboard/views/widgets/stat_card.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AnalyticsController>();
    final s = controller.snapshot;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navAnalytics),
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
                child: _buildTasksPieChart(s, colorScheme),
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
                      _buildHabitsProgress(s, colorScheme),
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
                        _getProgressColor(s.habitsDoneToday, s.totalHabits),
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
                  value: _getCompletionRate(s.completedTasks, s.activeTasks),
                  iconColor: Colors.green,
                ),
                const Divider(height: 1),
                QuickStatTile(
                  icon: Icons.schedule,
                  label: 'On-time Rate',
                  value: _getOnTimeRate(s.overdueTasks, s.activeTasks),
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

  Widget _buildTasksPieChart(AnalyticsSnapshot s, ColorScheme colorScheme) {
    final total = s.activeTasks + s.completedTasks + s.overdueTasks;
    if (total == 0) {
      return const Center(child: Text('No tasks yet'));
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                if (s.activeTasks > 0)
                  PieChartSectionData(
                    value: s.activeTasks.toDouble(),
                    title: '${s.activeTasks}',
                    color: colorScheme.primary,
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                if (s.completedTasks > 0)
                  PieChartSectionData(
                    value: s.completedTasks.toDouble(),
                    title: '${s.completedTasks}',
                    color: Colors.green,
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                if (s.overdueTasks > 0)
                  PieChartSectionData(
                    value: s.overdueTasks.toDouble(),
                    title: '${s.overdueTasks}',
                    color: Colors.orange,
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LegendItem(color: colorScheme.primary, label: 'Active'),
            const SizedBox(height: 8),
            LegendItem(color: Colors.green, label: 'Completed'),
            const SizedBox(height: 8),
            LegendItem(color: Colors.orange, label: 'Overdue'),
          ],
        ),
      ],
    );
  }

  Widget _buildHabitsProgress(AnalyticsSnapshot s, ColorScheme colorScheme) {
    final percentage = s.totalHabits > 0
        ? (s.habitsDoneToday / s.totalHabits * 100).round()
        : 0;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
      ),
      child: Center(
        child: Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(int done, int total) {
    if (total == 0) return Colors.grey;
    final ratio = done / total;
    if (ratio >= 0.8) return Colors.green;
    if (ratio >= 0.5) return Colors.orange;
    return Colors.red;
  }

  String _getCompletionRate(int completed, int active) {
    final total = completed + active;
    if (total == 0) return '0%';
    return '${(completed / total * 100).round()}%';
  }

  String _getOnTimeRate(int overdue, int active) {
    if (active == 0) return '100%';
    final onTime = active - overdue;
    return '${(onTime / active * 100).round()}%';
  }
}
