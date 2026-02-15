import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/platform/permission_service.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/analytics/controllers/analytics_controller.dart';
import 'package:nexus/features/calendar/controllers/calendar_controller.dart';
import 'package:nexus/features/habits/controllers/habit_controller.dart';
import 'package:nexus/features/habits/models/habit_log_repository.dart';
import 'package:nexus/features/habits/models/habit_repository.dart';
import 'package:nexus/features/notes/controllers/note_controller.dart';
import 'package:nexus/features/notes/models/note_repository.dart';
import 'package:nexus/features/reminders/controllers/reminder_controller.dart';
import 'package:nexus/features/reminders/models/reminder_repository.dart';
import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/sync/controllers/sync_controller.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task_repository.dart';

/// Result of complete initialization containing all providers and services
class AppInitializationResult {
  final SettingsController settingsController;
  final String deviceId;
  final ConnectivityService connectivityService;
  final SyncService syncService;
  final NotificationService notificationService;
  final PermissionService permissionService;
  final GoogleDriveService googleDriveService;
  final TaskRepository taskRepo;
  final TaskController taskController;
  final SyncController syncController;
  final ReminderRepository reminderRepo;
  final ReminderController reminderController;
  final NoteRepository noteRepo;
  final NoteController noteController;
  final HabitRepository habitRepo;
  final HabitLogRepository habitLogRepo;
  final HabitController habitController;
  final AnalyticsController analyticsController;
  final CalendarController calendarController;

  AppInitializationResult({
    required this.settingsController,
    required this.deviceId,
    required this.connectivityService,
    required this.syncService,
    required this.notificationService,
    required this.permissionService,
    required this.googleDriveService,
    required this.taskRepo,
    required this.taskController,
    required this.syncController,
    required this.reminderRepo,
    required this.reminderController,
    required this.noteRepo,
    required this.noteController,
    required this.habitRepo,
    required this.habitLogRepo,
    required this.habitController,
    required this.analyticsController,
    required this.calendarController,
  });
}
