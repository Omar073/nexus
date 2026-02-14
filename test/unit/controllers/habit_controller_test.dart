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

  group('HabitController', () {
    test('createHabit adds to habits list', () async {
      final habit = await controller.createHabit(title: 'Exercise');

      expect(habit.title, 'Exercise');
      expect(controller.habits, contains(habit));
    });

    test('toggleToday completes habit for today', () async {
      final habit = await controller.createHabit(title: 'Read');

      await controller.toggleToday(habit);

      expect(controller.isCompletedToday(habit.id), isTrue);
    });

    test('toggleToday twice uncompletes', () async {
      final habit = await controller.createHabit(title: 'Meditate');

      await controller.toggleToday(habit);
      await controller.toggleToday(habit);

      expect(controller.isCompletedToday(habit.id), isFalse);
    });

    test('currentStreak counts consecutive days including today', () async {
      final habit = await controller.createHabit(title: 'Run');

      // Manually create logs for the last 3 days
      final now = DateTime.now();
      for (var i = 0; i < 3; i++) {
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

      expect(controller.currentStreak(habit.id), 3);
    });

    test('currentStreak breaks on missing day', () async {
      final habit = await controller.createHabit(title: 'Code');
      final now = DateTime.now();

      // Today and 2 days ago (skip yesterday)
      await logRepo.upsert(
        HabitLog(
          id: 'log-today',
          habitId: habit.id,
          dayKey: HabitController.dayKey(now),
          completed: true,
          createdAt: now,
        ),
      );
      await logRepo.upsert(
        HabitLog(
          id: 'log-2ago',
          habitId: habit.id,
          dayKey: HabitController.dayKey(now.subtract(const Duration(days: 2))),
          completed: true,
          createdAt: now,
        ),
      );

      // Streak is only 1 (today) since yesterday is missing
      expect(controller.currentStreak(habit.id), 1);
    });
  });
}
