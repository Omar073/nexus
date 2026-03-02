import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/nexus_card.dart';
import 'package:nexus/core/widgets/section_header.dart';
import 'package:nexus/features/analytics/presentation/state_management/analytics_controller.dart';
import 'package:nexus/features/analytics/presentation/utils/analytics_utils.dart';
import 'package:nexus/features/analytics/presentation/widgets/habits_progress_circle.dart';
import 'package:nexus/features/analytics/presentation/widgets/habit_heatmap.dart';
import 'package:nexus/features/analytics/presentation/widgets/task_velocity_chart.dart';
import 'package:nexus/features/analytics/presentation/widgets/tasks_pie_chart.dart';
import 'package:nexus/core/widgets/app_drawer_button.dart';
import 'package:nexus/features/wrapper/presentation/widgets/app_drawer.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:provider/provider.dart';

/// Analytics screen following Nexus design system.
/// Features drawer button, overview stats cards, charts, and insights.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = context.watch<AnalyticsController>();
    final s = controller.snapshot;
    final colorScheme = theme.colorScheme;
    final navBarStyle = context.watch<SettingsController>().navBarStyle;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const AppDrawerButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () {
              showDateRangePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
                initialDateRange: DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 30)),
                  end: DateTime.now(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: navBarStyle.contentPadding),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your productivity insights',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Overview Stats Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  icon: Icons.checklist_rounded,
                  label: 'Active Tasks',
                  value: s.activeTasks.toString(),
                  color: colorScheme.primary,
                  isDark: isDark,
                ),
                _StatCard(
                  icon: Icons.check_circle_outline,
                  label: 'Completed',
                  value: s.completedTasks.toString(),
                  color: Colors.green,
                  isDark: isDark,
                ),
                _StatCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'Overdue',
                  value: s.overdueTasks.toString(),
                  color: Colors.orange,
                  isDark: isDark,
                ),
                _StatCard(
                  icon: Icons.alarm,
                  label: 'Reminders',
                  value: s.upcomingReminders.toString(),
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tasks Status Section (Pie)
          SectionHeader(
            title: 'Tasks Overview',
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: NexusCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 16,
                    child: SizedBox(
                      height: 180,
                      child: TasksPieChart(
                        snapshot: s,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Task Velocity Section
          SectionHeader(
            title: 'Task Velocity',
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NexusCard(
              padding: const EdgeInsets.all(24),
              borderRadius: 16,
              child: SizedBox(
                height: 200,
                child: TaskVelocityChart(snapshot: s, colorScheme: colorScheme),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Habits Progress Section
          SectionHeader(
            title: 'Habits Today',
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NexusCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Progress",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${s.habitsDoneToday}/${s.totalHabits}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'habits completed',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: s.totalHabits > 0
                                ? s.habitsDoneToday / s.totalHabits
                                : 0,
                            minHeight: 10,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              getProgressColor(
                                s.habitsDoneToday,
                                s.totalHabits,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: HabitsProgressCircle(
                      snapshot: s,
                      colorScheme: colorScheme,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Habit Consistency Heatmap
          SectionHeader(
            title: 'Habit Consistency',
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NexusCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 16,
              child: HabitHeatmap(colorScheme: colorScheme),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Stats Section
          SectionHeader(
            title: 'Performance',
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NexusCard(
              padding: EdgeInsets.zero,
              borderRadius: 16,
              child: Column(
                children: [
                  _QuickStatRow(
                    icon: Icons.trending_up,
                    label: 'Completion Rate',
                    value: getCompletionRate(s.completedTasks, s.activeTasks),
                    color: Colors.green,
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                  ),
                  _QuickStatRow(
                    icon: Icons.schedule,
                    label: 'On-time Rate',
                    value: getOnTimeRate(s.overdueTasks, s.activeTasks),
                    color: Colors.blue,
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                  ),
                  _QuickStatRow(
                    icon: Icons.loop,
                    label: 'Active Habits',
                    value: '${s.totalHabits} habits',
                    color: Colors.purple,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Stat card widget for the overview grid
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : theme.colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick stat row widget
class _QuickStatRow extends StatelessWidget {
  const _QuickStatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
