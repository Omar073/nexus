import 'dart:async';

import 'package:nexus/features/habits/data/mappers/habit_log_mapper.dart';
import 'package:nexus/features/habits/domain/entities/habit_log_entity.dart';
import 'package:nexus/features/habits/domain/repositories/habit_log_repository_interface.dart';
import 'package:nexus/features/habits/data/data_sources/habit_log_local_datasource.dart';

/// Implements habit log persistence via local datasource.

class HabitLogRepositoryImpl implements HabitLogRepositoryInterface {
  HabitLogRepositoryImpl({HabitLogLocalDatasource? local})
    : _local = local ?? HabitLogLocalDatasource() {
    _changesController = StreamController<void>.broadcast();
    _local.listenable().addListener(_notifyChanges);
  }

  final HabitLogLocalDatasource _local;
  late final StreamController<void> _changesController;

  void _notifyChanges() {
    _changesController.add(null);
  }

  @override
  List<HabitLogEntity> getAll() {
    return _local.getAll().map(HabitLogMapper.toEntity).toList();
  }

  @override
  List<HabitLogEntity> getByHabitId(String habitId) {
    return _local
        .getAll()
        .where((log) => log.habitId == habitId)
        .map(HabitLogMapper.toEntity)
        .toList();
  }

  @override
  Future<void> upsert(HabitLogEntity log) async {
    await _local.put(HabitLogMapper.toModel(log));
    _notifyChanges();
  }

  @override
  Future<void> delete(String id) async {
    await _local.delete(id);
    _notifyChanges();
  }

  @override
  Stream<void> get changes => _changesController.stream;

  void dispose() {
    _local.listenable().removeListener(_notifyChanges);
    _changesController.close();
  }
}
