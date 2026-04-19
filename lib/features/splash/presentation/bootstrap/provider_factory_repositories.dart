import 'package:nexus/features/habits/data/repositories/habit_log_repository_impl.dart';
import 'package:nexus/features/habits/data/repositories/habit_repository_impl.dart';
import 'package:nexus/features/habits/domain/repositories/habit_log_repository_interface.dart';
import 'package:nexus/features/habits/domain/repositories/habit_repository_interface.dart';
import 'package:nexus/features/notes/data/repositories/note_repository_impl.dart';
import 'package:nexus/features/notes/domain/repositories/note_repository_interface.dart';
import 'package:nexus/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';
import 'package:nexus/features/splash/presentation/models/app_initialization_result.dart';
import 'package:nexus/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:nexus/features/tasks/domain/repositories/task_repository_interface.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> createAppRepositoryProviders(
  AppInitializationResult? fullResult,
) {
  return [
    Provider<TaskRepositoryInterface>(
      create: (_) => fullResult?.taskRepo ?? TaskRepositoryImpl(),
    ),
    Provider<ReminderRepositoryInterface>(
      create: (_) => fullResult?.reminderRepo ?? ReminderRepositoryImpl(),
    ),
    Provider<NoteRepositoryInterface>(
      create: (_) => fullResult?.noteRepo ?? NoteRepositoryImpl(),
    ),
    Provider<HabitRepositoryInterface>(
      create: (_) => fullResult?.habitRepo ?? HabitRepositoryImpl(),
    ),
    Provider<HabitLogRepositoryInterface>(
      create: (_) => fullResult?.habitLogRepo ?? HabitLogRepositoryImpl(),
    ),
  ];
}
