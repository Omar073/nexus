import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/sync_metadata.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/features/habits/models/habit.dart';
import 'package:nexus/features/habits/models/habit_log.dart';
import 'package:nexus/features/notes/models/note.dart';
import 'package:nexus/features/notes/models/note_attachment.dart';
import 'package:nexus/features/reminders/models/reminder.dart';
import 'package:nexus/features/tasks/models/category.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_attachment.dart';

class HiveBootstrap {
  static bool _registered = false;

  static void registerAdapters() {
    if (_registered) return;
    _registered = true;

    Hive
      ..registerAdapter(CategoryAdapter())
      ..registerAdapter(TaskAttachmentAdapter())
      ..registerAdapter(TaskAdapter())
      ..registerAdapter(SyncOperationAdapter())
      ..registerAdapter(ReminderAdapter())
      ..registerAdapter(SyncMetadataAdapter())
      ..registerAdapter(NoteAttachmentAdapter())
      ..registerAdapter(NoteAdapter())
      ..registerAdapter(HabitAdapter())
      ..registerAdapter(HabitLogAdapter());
  }

  static Future<void> openBoxes() async {
    await Hive.openBox<Category>(HiveBoxes.categories);
    await Hive.openBox<Task>(HiveBoxes.tasks);
    await Hive.openBox<Reminder>(HiveBoxes.reminders);
    await Hive.openBox<Note>(HiveBoxes.notes);
    await Hive.openBox<Habit>(HiveBoxes.habits);
    await Hive.openBox<HabitLog>(HiveBoxes.habitLogs);
    await Hive.openBox<SyncOperation>(HiveBoxes.syncOps);
    await Hive.openBox<SyncMetadata>(HiveBoxes.syncMetadata);
  }
}
