import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/core/data/hive_boxes.dart';
import 'package:nexus/features/tasks/models/task.dart';

class TaskLocalDatasource {
  Box<Task> get _box => Hive.box<Task>(HiveBoxes.tasks);

  List<Task> getAll() => _box.values.toList(growable: false);

  Task? getById(String id) => _box.get(id);

  Future<void> put(Task task) => _box.put(task.id, task);

  Future<void> delete(String id) => _box.delete(id);

  ValueListenable<Box<Task>> listenable() => _box.listenable();
}


