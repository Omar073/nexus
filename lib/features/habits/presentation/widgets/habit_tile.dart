import 'package:flutter/material.dart';
import 'package:nexus/features/habits/presentation/state_management/habit_controller.dart';
import 'package:nexus/features/habits/domain/entities/habit_entity.dart';
import 'package:nexus/features/habits/presentation/pages/habit_details_screen.dart';
import 'package:provider/provider.dart';

/// Dense habit row variant for lists and pickers.
class HabitTile extends StatelessWidget {
  const HabitTile({super.key, required this.habit});

  final HabitEntity habit;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HabitController>();
    final done = controller.isCompletedToday(habit.id);
    final streak = controller.currentStreak(habit.id);

    return ListTile(
      leading: Checkbox(
        value: done,
        onChanged: (_) => controller.toggleToday(habit),
      ),
      title: Text(habit.name),
      subtitle: Text('Streak: $streak'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HabitDetailsScreen(habitId: habit.id),
        ),
      ),
    );
  }
}
