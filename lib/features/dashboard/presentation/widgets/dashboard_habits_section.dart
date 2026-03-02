import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/habit_pill.dart';
import 'package:nexus/features/habits/presentation/state_management/habit_controller.dart';
import 'package:provider/provider.dart';

/// Dashboard section showing habit pills with completion status.
class DashboardHabitsSection extends StatelessWidget {
  const DashboardHabitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final habitController = context.watch<HabitController>();
    final habits = habitController.habits;

    if (habits.isEmpty) {
      // When there are no habits yet, don't show fake placeholder habits.
      // The dedicated Habits screen already explains how to create habits.
      return const SizedBox.shrink();
    }

    return HabitPillBar(
      habits: habits
          .take(5)
          .map(
            (h) => HabitPillData(
              icon: Icons.check_circle_outline,
              label: h.name,
              iconColor: Theme.of(context).colorScheme.primary,
              isCompleted: habitController.isCompletedToday(h.id),
            ),
          )
          .toList(),
    );
  }
}
