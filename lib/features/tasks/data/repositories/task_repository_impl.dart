import 'dart:async';

import 'package:nexus/features/tasks/data/mappers/task_mapper.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/repositories/task_repository_interface.dart';
import 'package:nexus/features/tasks/data/data_sources/task_local_datasource.dart';

/// Implements [TaskRepositoryInterface] using [TaskLocalDatasource] and [TaskMapper].
class TaskRepositoryImpl implements TaskRepositoryInterface {
  TaskRepositoryImpl({TaskLocalDatasource? local})
    : _local = local ?? TaskLocalDatasource() {
    _local.listenable().addListener(_onBoxChanged);
  }

  final TaskLocalDatasource _local;
  final _changeController = StreamController<void>.broadcast();

  void _onBoxChanged() {
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
  }

  @override
  List<TaskEntity> getAll() =>
      _local.getAll().map(TaskMapper.toEntity).toList();

  @override
  TaskEntity? getById(String id) {
    final t = _local.getById(id);
    return t != null ? TaskMapper.toEntity(t) : null;
  }

  @override
  Future<void> upsert(TaskEntity task) async {
    final model = TaskMapper.toModel(task);
    await _local.put(model);
  }

  @override
  Future<void> delete(String id) async {
    await _local.delete(id);
  }

  @override
  Stream<void> get changes => _changeController.stream;

  @override
  Map<String, dynamic>? getSyncPayload(String id) {
    final t = _local.getById(id);
    return t?.toFirestoreJson();
  }
}
