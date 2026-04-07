import 'dart:async';

import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/features/reminders/data/mappers/reminder_mapper.dart';
import 'package:nexus/features/reminders/data/models/reminder.dart';
import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';
import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';
import 'package:nexus/features/reminders/data/data_sources/reminder_local_datasource.dart';

/// Implements reminder persistence via local datasource.

class ReminderRepositoryImpl implements ReminderRepositoryInterface {
  ReminderRepositoryImpl({ReminderLocalDatasource? local})
    : _local = local ?? ReminderLocalDatasource() {
    _changesController = StreamController<void>.broadcast();
    _local.listenable().addListener(_notifyChanges);
  }

  final ReminderLocalDatasource _local;
  late final StreamController<void> _changesController;

  void _notifyChanges() {
    _changesController.add(null);
  }

  @override
  List<ReminderEntity> getAll() {
    return _local.getAll().map(ReminderMapper.toEntity).toList();
  }

  @override
  ReminderEntity? getById(String id) {
    final r = _local.getById(id);
    return r == null ? null : ReminderMapper.toEntity(r);
  }

  @override
  Future<void> upsert(ReminderEntity reminder) async {
    await _local.put(ReminderMapper.toModel(reminder));
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
    final box = Hive.box<Reminder>(HiveBoxes.reminders);
    final reminder = box.get(id);
    return reminder?.toFirestoreJson();
  }

  @override
  Future<void> markNotified(String id) async {
    final box = Hive.box<Reminder>(HiveBoxes.reminders);
    final reminder = box.get(id);
    if (reminder == null) return;
    if (reminder.completedAt != null) return;
    reminder.notifiedAt = DateTime.now();
    await reminder.save();
  }

  void dispose() {
    _local.listenable().removeListener(_notifyChanges);
    _changesController.close();
  }
}
