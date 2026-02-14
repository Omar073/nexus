import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/features/habits/controllers/habit_controller.dart';
import 'package:nexus/features/habits/models/habit.dart';
import 'package:nexus/features/habits/models/habit_log.dart';
import 'package:nexus/features/habits/models/habit_repository.dart';
import 'package:nexus/features/habits/models/habit_log_repository.dart';

/// E2E-style test: Create → toggle → verify streak.
void main() {
  late HabitRepository habitRepo;
  late HabitLogRepository logRepo;
  late HabitController controller;

  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.habit)) {
      Hive.registerAdapter(HabitAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.habitLog)) {
      Hive.registerAdapter(HabitLogAdapter());
    }
    await Hive.openBox<Habit>(HiveBoxes.habits);
    await Hive.openBox<HabitLog>(HiveBoxes.habitLogs);
    habitRepo = HabitRepository();
    logRepo = HabitLogRepository();
    controller = HabitController(habits: habitRepo, logs: logRepo);
  });

  tearDown(() async {
    controller.dispose();
    await tearDownTestHive();
  });

  group('Habit Tracking E2E', () {
    test('full flow: create → toggle today → verify streak = 1', () async {
      // 1. Create
      final habit = await controller.createHabit(title: 'Daily standup');
      expect(controller.habits.length, 1);

      // 2. Toggle today
      await controller.toggleToday(habit);
      expect(controller.isCompletedToday(habit.id), isTrue);

      // 3. Streak should be 1
      expect(controller.currentStreak(habit.id), 1);
    });

    test('streak accumulates with backdated logs', () async {
      final habit = await controller.createHabit(title: 'Stretching');

      // Backdate 5 consecutive days
      final now = DateTime.now();
      for (var i = 0; i < 5; i++) {
        final day = now.subtract(Duration(days: i));
        await logRepo.upsert(
          HabitLog(
            id: 'log-$i',
            habitId: habit.id,
            dayKey: HabitController.dayKey(day),
            completed: true,
            createdAt: day,
          ),
        );
      }

      expect(controller.currentStreak(habit.id), 5);
    });
  });
}
