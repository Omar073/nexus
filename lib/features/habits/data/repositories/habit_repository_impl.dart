import 'dart:async';

import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/features/habits/data/mappers/habit_mapper.dart';
import 'package:nexus/features/habits/domain/entities/habit_entity.dart';
import 'package:nexus/features/habits/domain/repositories/habit_repository_interface.dart';
import 'package:nexus/features/habits/data/data_sources/habit_local_datasource.dart';
import 'package:nexus/features/habits/data/models/habit.dart';

class HabitRepositoryImpl implements HabitRepositoryInterface {
  HabitRepositoryImpl({HabitLocalDatasource? local})
    : _local = local ?? HabitLocalDatasource() {
    _changesController = StreamController<void>.broadcast();
    _local.listenable().addListener(_notifyChanges);
  }

  final HabitLocalDatasource _local;
  late final StreamController<void> _changesController;

  void _notifyChanges() {
    _changesController.add(null);
  }

  @override
  List<HabitEntity> getAll() {
    return _local.getAll().map(HabitMapper.toEntity).toList();
  }

  @override
  HabitEntity? getById(String id) {
    final h = _local.getById(id);
    return h == null ? null : HabitMapper.toEntity(h);
  }

  @override
  Future<void> upsert(HabitEntity habit) async {
    await _local.put(HabitMapper.toModel(habit));
    _notifyChanges();
  }

  @override
  Future<void> delete(String id) async {
    await _local.delete(id);
    _notifyChanges();
  }

  @override
  Stream<void> get changes => _changesController.stream;

  @override
  Map<String, dynamic>? getSyncPayload(String id) {
    final box = Hive.box<Habit>(HiveBoxes.habits);
    final habit = box.get(id);
    return habit?.toFirestoreJson();
  }

  void dispose() {
    _local.listenable().removeListener(_notifyChanges);
    _changesController.close();
  }
}
