import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/sync_metadata.dart';
import 'package:nexus/core/data/sync_operation_adapter.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/features/habits/data/models/habit.dart';
import 'package:nexus/features/habits/data/models/habit_log.dart';
import 'package:nexus/features/notes/data/models/note.dart';
import 'package:nexus/features/notes/data/models/note_attachment.dart';
import 'package:nexus/features/reminders/data/models/reminder.dart';
import 'package:nexus/features/categories/data/models/category.dart';
import 'package:nexus/features/tasks/data/models/task.dart';
import 'package:nexus/features/tasks/data/models/task_attachment.dart';

/// Registers all Hive adapters and opens boxes.
/// Lives in app so core/data has no feature imports.
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
