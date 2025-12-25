import 'package:flutter/material.dart';
import 'package:nexus/features/habits/controllers/habit_controller.dart';
import 'package:nexus/features/habits/views/widgets/habit_create_dialog.dart';
import 'package:nexus/features/habits/views/widgets/habit_tile.dart';
import 'package:provider/provider.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HabitController>();
    final habits = controller.habits;

    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: habits.isEmpty
          ? const Center(child: Text('No habits'))
          : ListView.separated(
              itemCount: habits.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return HabitTile(habit: habits[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'habits_fab',
        onPressed: () => showHabitCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
