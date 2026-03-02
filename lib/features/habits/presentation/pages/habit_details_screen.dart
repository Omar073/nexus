import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nexus/features/habits/presentation/state_management/habit_controller.dart';
import 'package:provider/provider.dart';

class HabitDetailsScreen extends StatelessWidget {
  const HabitDetailsScreen({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HabitController>();
    final habit = controller.habits.firstWhere((h) => h.id == habitId);
    final streak = controller.currentStreak(habitId);

    // Last 14 days completion series.
    final today = DateTime.now();
    final points = <FlSpot>[];
    for (var i = 13; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final key = HabitController.dayKey(day);
      final completed = controller.logs.any(
        (l) =>
            l.habitId == habitId &&
            HabitController.dayKey(l.date) == key &&
            l.completed,
      );
      points.add(FlSpot((13 - i).toDouble(), completed ? 1 : 0));
    }

    return Scaffold(
      appBar: AppBar(title: Text(habit.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current streak: $streak',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 1,
                  titlesData: const FlTitlesData(show: false),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points,
                      isCurved: false,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Last 14 days (1=done, 0=missed)'),
          ],
        ),
      ),
    );
  }
}
