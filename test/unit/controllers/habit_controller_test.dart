import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/habits/presentation/state_management/habit_controller.dart';
import 'package:nexus/features/habits/data/models/habit.dart';
import 'package:nexus/features/habits/data/models/habit_log.dart';
import 'package:nexus/features/habits/domain/repositories/habit_repository_interface.dart';
import 'package:nexus/features/habits/domain/repositories/habit_log_repository_interface.dart';
import 'package:nexus/features/habits/data/repositories/habit_repository_impl.dart';
import 'package:nexus/features/habits/domain/entities/habit_log_entity.dart';
import 'package:nexus/features/habits/data/repositories/habit_log_repository_impl.dart';

void main() {
  late HabitRepositoryInterface habitRepo;
  late HabitLogRepositoryInterface logRepo;
  late SyncService syncService;
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
    habitRepo = HabitRepositoryImpl();
    logRepo = HabitLogRepositoryImpl();
    syncService = _FakeSyncService();
    controller = HabitController(
      habits: habitRepo,
      logs: logRepo,
      syncService: syncService,
    );
  });

  tearDown(() async {
    controller.dispose();
    await tearDownTestHive();
  });

  group('HabitController', () {
    test('createHabit adds to habits list', () async {
      final habit = await controller.createHabit(title: 'Exercise');

      expect(habit.name, 'Exercise');
      expect(controller.habits.any((h) => h.id == habit.id), isTrue);
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
          HabitLogEntity(
            id: 'log-$i',
            habitId: habit.id,
            date: day,
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
        HabitLogEntity(
          id: 'log-today',
          habitId: habit.id,
          date: now,
          completed: true,
          createdAt: now,
        ),
      );
      await logRepo.upsert(
        HabitLogEntity(
          id: 'log-2ago',
          habitId: habit.id,
          date: now.subtract(const Duration(days: 2)),
          completed: true,
          createdAt: now,
        ),
      );

      // Streak is only 1 (today) since yesterday is missing
      expect(controller.currentStreak(habit.id), 1);
    });
  });
}

class _FakeSyncService extends SyncService {
  _FakeSyncService() : super(connectivity: ConnectivityService());

  @override
  Future<void> enqueueOperation(SyncOperation op) async {
    // no-op for tests
  }

  @override
  Future<void> syncOnce() async {
    // no-op for tests
  }
}
