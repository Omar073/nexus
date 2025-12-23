import 'package:flutter/foundation.dart';
import 'package:nexus/features/reminders/models/reminder_local_datasource.dart';
import 'package:nexus/features/reminders/models/reminder.dart';

class ReminderRepository {
  ReminderRepository({ReminderLocalDatasource? local})
    : _local = local ?? ReminderLocalDatasource();

  final ReminderLocalDatasource _local;

  List<Reminder> getAll() => _local.getAll();

  Reminder? getById(String id) => _local.getById(id);

  Future<void> upsert(Reminder reminder) => _local.put(reminder);

  Future<void> delete(String id) => _local.delete(id);

  ValueListenable listenable() => _local.listenable();
}
