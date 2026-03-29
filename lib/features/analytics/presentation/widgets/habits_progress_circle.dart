import 'package:flutter/material.dart';
import 'package:nexus/features/analytics/presentation/state_management/analytics_controller.dart';

/// Radial progress for habits completed this period.
class HabitsProgressCircle extends StatelessWidget {
  const HabitsProgressCircle({
    super.key,
    required this.snapshot,
    required this.colorScheme,
  });

  final AnalyticsSnapshot snapshot;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final percentage = snapshot.totalHabits > 0
        ? (snapshot.habitsDoneToday / snapshot.totalHabits * 100).round()
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
}
