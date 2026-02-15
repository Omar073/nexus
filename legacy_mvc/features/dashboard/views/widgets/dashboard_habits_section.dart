import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/habit_pill.dart';
import 'package:nexus/features/habits/controllers/habit_controller.dart';
import 'package:provider/provider.dart';

/// Dashboard section showing habit pills with completion status.
class DashboardHabitsSection extends StatelessWidget {
  const DashboardHabitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final habitController = context.watch<HabitController>();
    final habits = habitController.habits;

    if (habits.isEmpty) {
      return HabitPillBar(
        habits: [
          HabitPillData(
            icon: Icons.water_drop,
            label: 'Water 0/3L',
            iconColor: Colors.cyan,
          ),
          HabitPillData(
            icon: Icons.fitness_center,
            label: 'Gym',
            iconColor: Colors.blue,
            isCompleted: true,
          ),
          HabitPillData(
            icon: Icons.menu_book,
            label: 'Read 10 pages of Quran',
            iconColor: Colors.green,
          ),
        ],
      );
    }

    return HabitPillBar(
      habits: habits
          .take(5)
          .map(
            (h) => HabitPillData(
              icon: Icons.check_circle_outline,
              label: h.title,
              iconColor: Theme.of(context).colorScheme.primary,
              isCompleted: false,
            ),
          )
          .toList(),
    );
  }
}
