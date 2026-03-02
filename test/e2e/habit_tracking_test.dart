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
import 'package:nexus/features/habits/domain/entities/habit_log_entity.dart';
import 'package:nexus/features/habits/data/models/habit_log.dart';
import 'package:nexus/features/habits/domain/repositories/habit_repository_interface.dart';
import 'package:nexus/features/habits/domain/repositories/habit_log_repository_interface.dart';
import 'package:nexus/features/habits/data/repositories/habit_repository_impl.dart';
import 'package:nexus/features/habits/data/repositories/habit_log_repository_impl.dart';

/// E2E-style test: Create → toggle → verify streak.
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
          HabitLogEntity(
            id: 'log-$i',
            habitId: habit.id,
            date: day,
            completed: true,
            createdAt: day,
          ),
        );
      }

      expect(controller.currentStreak(habit.id), 5);
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
