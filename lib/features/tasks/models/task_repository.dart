import 'package:flutter/foundation.dart';
import 'package:nexus/features/tasks/models/task_local_datasource.dart';
import 'package:nexus/features/tasks/models/task.dart';

class TaskRepository {
  TaskRepository({TaskLocalDatasource? local})
    : _local = local ?? TaskLocalDatasource();

  final TaskLocalDatasource _local;

  List<Task> getAll() => _local.getAll();

  Task? getById(String id) => _local.getById(id);

  Future<void> upsert(Task task) => _local.put(task);

  Future<void> delete(String id) => _local.delete(id);

  ValueListenable listenable() => _local.listenable();
}
