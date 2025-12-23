import 'package:flutter/foundation.dart';
import 'package:nexus/features/habits/models/habit_local_datasource.dart';
import 'package:nexus/features/habits/models/habit.dart';

class HabitRepository {
  HabitRepository({HabitLocalDatasource? local})
    : _local = local ?? HabitLocalDatasource();

  final HabitLocalDatasource _local;

  List<Habit> getAll() => _local.getAll();

  Habit? getById(String id) => _local.getById(id);

  Future<void> upsert(Habit habit) => _local.put(habit);

  Future<void> delete(String id) => _local.delete(id);

  ValueListenable listenable() => _local.listenable();
}
