import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/features/habits/models/habit_log.dart';

class HabitLogLocalDatasource {
  Box<HabitLog> get _box => Hive.box<HabitLog>(HiveBoxes.habitLogs);

  List<HabitLog> getAll() => _box.values.toList(growable: false);

  Future<void> put(HabitLog log) => _box.put(log.id, log);

  Future<void> delete(String id) => _box.delete(id);

  ValueListenable<Box<HabitLog>> listenable() => _box.listenable();
}
