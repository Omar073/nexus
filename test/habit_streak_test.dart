import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive_boxes.dart';
import 'package:nexus/features/habits/controllers/habit_controller.dart';
import 'package:nexus/features/habits/models/habit.dart';
import 'package:nexus/features/habits/models/habit_log.dart';
import 'package:nexus/features/habits/models/habit_log_repository.dart';
import 'package:nexus/features/habits/models/habit_repository.dart';

void main() {
  test('currentStreak counts consecutive completed days', () async {
    await setUpTestHive();
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitLogAdapter());
    await Hive.openBox<Habit>(HiveBoxes.habits);
    await Hive.openBox<HabitLog>(HiveBoxes.habitLogs);

    final habits = HabitRepository();
    final logs = HabitLogRepository();
    final controller = HabitController(habits: habits, logs: logs);

    final habit = await controller.createHabit(title: 'Test');

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDays = today.subtract(const Duration(days: 2));

    await logs.upsert(
      HabitLog(
        id: '1',
        habitId: habit.id,
        dayKey: HabitController.dayKey(today),
        completed: true,
        createdAt: DateTime.now(),
      ),
    );
    await logs.upsert(
      HabitLog(
        id: '2',
        habitId: habit.id,
        dayKey: HabitController.dayKey(yesterday),
        completed: true,
        createdAt: DateTime.now(),
      ),
    );
    await logs.upsert(
      HabitLog(
        id: '3',
        habitId: habit.id,
        dayKey: HabitController.dayKey(twoDays),
        completed: false,
        createdAt: DateTime.now(),
      ),
    );

    expect(controller.currentStreak(habit.id), 2);

    await tearDownTestHive();
  });
}
