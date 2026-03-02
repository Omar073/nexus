import 'package:nexus/features/habits/domain/entities/habit_entity.dart';

/// Contract for habit persistence (pure Dart).
abstract class HabitRepositoryInterface {
  List<HabitEntity> getAll();
  HabitEntity? getById(String id);
  Future<void> upsert(HabitEntity habit);
  Future<void> delete(String id);
  Stream<void> get changes;

  Map<String, dynamic>? getSyncPayload(String id);
}
