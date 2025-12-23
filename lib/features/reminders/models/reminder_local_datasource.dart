import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/core/data/hive_boxes.dart';
import 'package:nexus/features/reminders/models/reminder.dart';

class ReminderLocalDatasource {
  Box<Reminder> get _box => Hive.box<Reminder>(HiveBoxes.reminders);

  List<Reminder> getAll() => _box.values.toList(growable: false);

  Reminder? getById(String id) => _box.get(id);

  Future<void> put(Reminder reminder) => _box.put(reminder.id, reminder);

  Future<void> delete(String id) => _box.delete(id);

  ValueListenable<Box<Reminder>> listenable() => _box.listenable();
}


