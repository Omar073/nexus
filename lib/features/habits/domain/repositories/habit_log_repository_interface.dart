import 'package:nexus/features/habits/domain/entities/habit_log_entity.dart';

/// Contract for habit log persistence (pure Dart).
abstract class HabitLogRepositoryInterface {
  List<HabitLogEntity> getAll();
  List<HabitLogEntity> getByHabitId(String habitId);
  Future<void> upsert(HabitLogEntity log);
  Future<void> delete(String id);
  Stream<void> get changes;
}
