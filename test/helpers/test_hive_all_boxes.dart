import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/core/data/sync_operation_adapter.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/features/categories/data/models/category.dart';
import 'package:nexus/features/habits/data/models/habit.dart';
import 'package:nexus/features/habits/data/models/habit_log.dart';
import 'package:nexus/features/notes/data/models/note.dart';
import 'package:nexus/features/notes/data/models/note_attachment.dart';
import 'package:nexus/features/reminders/data/models/reminder.dart';
import 'package:nexus/features/tasks/data/models/task.dart';
import 'package:nexus/features/tasks/data/models/task_attachment.dart';

/// Registers adapters and opens every feature Hive box used by screen smoke tests.
Future<void> setUpTestHiveAllBoxes() async {
  await setUpTestHive();
  _registerAllAdapters();
  await Future.wait<void>([
    Hive.openBox<Category>(HiveBoxes.categories),
    Hive.openBox<Task>(HiveBoxes.tasks),
    Hive.openBox<SyncOperation>(HiveBoxes.syncOps),
    Hive.openBox<Reminder>(HiveBoxes.reminders),
    Hive.openBox<Note>(HiveBoxes.notes),
    Hive.openBox<Habit>(HiveBoxes.habits),
    Hive.openBox<HabitLog>(HiveBoxes.habitLogs),
  ]);
}

void _registerAllAdapters() {
  if (!Hive.isAdapterRegistered(HiveTypeIds.category)) {
    Hive.registerAdapter(CategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.taskAttachment)) {
    Hive.registerAdapter(TaskAttachmentAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.task)) {
    Hive.registerAdapter(TaskAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.syncOperation)) {
    Hive.registerAdapter(SyncOperationAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.reminder)) {
    Hive.registerAdapter(ReminderAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.noteAttachment)) {
    Hive.registerAdapter(NoteAttachmentAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.note)) {
    Hive.registerAdapter(NoteAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.habit)) {
    Hive.registerAdapter(HabitAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.habitLog)) {
    Hive.registerAdapter(HabitLogAdapter());
  }
}
