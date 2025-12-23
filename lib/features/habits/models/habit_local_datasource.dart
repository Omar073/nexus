import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/core/data/hive_boxes.dart';
import 'package:nexus/features/habits/models/habit.dart';

class HabitLocalDatasource {
  Box<Habit> get _box => Hive.box<Habit>(HiveBoxes.habits);

  List<Habit> getAll() => _box.values.toList(growable: false);

  Habit? getById(String id) => _box.get(id);

  Future<void> put(Habit habit) => _box.put(habit.id, habit);

  Future<void> delete(String id) => _box.delete(id);

  ValueListenable<Box<Habit>> listenable() => _box.listenable();
}


