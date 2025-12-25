import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nexus/features/analytics/controllers/analytics_controller.dart';
import 'package:nexus/features/analytics/views/widgets/legend_item.dart';

/// Pie chart widget displaying task status distribution.
class TasksPieChart extends StatelessWidget {
  const TasksPieChart({
    super.key,
    required this.snapshot,
    required this.colorScheme,
  });

  final AnalyticsSnapshot snapshot;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final total =
        snapshot.activeTasks + snapshot.completedTasks + snapshot.overdueTasks;
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
                if (snapshot.activeTasks > 0)
                  PieChartSectionData(
                    value: snapshot.activeTasks.toDouble(),
                    title: '${snapshot.activeTasks}',
                    color: colorScheme.primary,
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                if (snapshot.completedTasks > 0)
                  PieChartSectionData(
                    value: snapshot.completedTasks.toDouble(),
                    title: '${snapshot.completedTasks}',
                    color: Colors.green,
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                if (snapshot.overdueTasks > 0)
                  PieChartSectionData(
                    value: snapshot.overdueTasks.toDouble(),
                    title: '${snapshot.overdueTasks}',
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
            const LegendItem(color: Colors.green, label: 'Completed'),
            const SizedBox(height: 8),
            const LegendItem(color: Colors.orange, label: 'Overdue'),
          ],
        ),
      ],
    );
  }
}
