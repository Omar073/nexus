import 'package:flutter/material.dart';
import 'package:nexus/features/habits/controllers/habit_controller.dart';
import 'package:nexus/features/habits/models/habit.dart';
import 'package:nexus/features/habits/views/habit_details_screen.dart';
import 'package:provider/provider.dart';

/// A list tile for displaying a habit with a checkbox and streak count.
class HabitTile extends StatelessWidget {
  const HabitTile({super.key, required this.habit});

  final Habit habit;

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
      title: Text(habit.title),
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
