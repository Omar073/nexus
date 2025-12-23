import 'package:flutter/foundation.dart';
import 'package:nexus/features/habits/models/habit_log_local_datasource.dart';
import 'package:nexus/features/habits/models/habit_log.dart';

class HabitLogRepository {
  HabitLogRepository({HabitLogLocalDatasource? local})
    : _local = local ?? HabitLogLocalDatasource();

  final HabitLogLocalDatasource _local;

  List<HabitLog> getAll() => _local.getAll();

  Future<void> upsert(HabitLog log) => _local.put(log);

  Future<void> delete(String id) => _local.delete(id);

  ValueListenable listenable() => _local.listenable();
}
