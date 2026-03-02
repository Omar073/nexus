import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/habits/presentation/state_management/habit_controller.dart';
import 'package:nexus/features/habits/domain/entities/habit_log_entity.dart';
import 'package:nexus/features/habits/data/models/habit.dart';
import 'package:nexus/features/habits/data/models/habit_log.dart';
import 'package:nexus/features/habits/data/repositories/habit_repository_impl.dart';
import 'package:nexus/features/habits/data/repositories/habit_log_repository_impl.dart';

void main() {
  test('currentStreak counts consecutive completed days', () async {
    await setUpTestHive();
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitLogAdapter());
    await Hive.openBox<Habit>(HiveBoxes.habits);
    await Hive.openBox<HabitLog>(HiveBoxes.habitLogs);

    final habits = HabitRepositoryImpl();
    final logs = HabitLogRepositoryImpl();
    final syncService = _FakeSyncService();
    final controller = HabitController(
      habits: habits,
      logs: logs,
      syncService: syncService,
    );

    final habit = await controller.createHabit(title: 'Test');

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDays = today.subtract(const Duration(days: 2));

    await logs.upsert(
      HabitLogEntity(
        id: '1',
        habitId: habit.id,
        date: today,
        completed: true,
        createdAt: DateTime.now(),
      ),
    );
    await logs.upsert(
      HabitLogEntity(
        id: '2',
        habitId: habit.id,
        date: yesterday,
        completed: true,
        createdAt: DateTime.now(),
      ),
    );
    await logs.upsert(
      HabitLogEntity(
        id: '3',
        habitId: habit.id,
        date: twoDays,
        completed: false,
        createdAt: DateTime.now(),
      ),
    );

    expect(controller.currentStreak(habit.id), 2);

    await tearDownTestHive();
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
