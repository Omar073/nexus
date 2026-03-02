import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/platform/permission_service.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/analytics/presentation/state_management/analytics_controller.dart';
import 'package:nexus/features/calendar/presentation/state_management/calendar_controller.dart';
import 'package:nexus/features/habits/presentation/state_management/habit_controller.dart';
import 'package:nexus/features/habits/domain/repositories/habit_log_repository_interface.dart';
import 'package:nexus/features/habits/domain/repositories/habit_repository_interface.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/notes/domain/repositories/note_repository_interface.dart';
import 'package:nexus/features/reminders/presentation/state_management/reminder_controller.dart';
import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/sync/presentation/state_management/sync_controller.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/domain/repositories/task_repository_interface.dart';

/// Result of complete initialization containing all providers and services
class AppInitializationResult {
  final SettingsController settingsController;
  final String deviceId;
  final ConnectivityService connectivityService;
  final SyncService syncService;
  final NotificationService notificationService;
  final PermissionService permissionService;
  final GoogleDriveService googleDriveService;
  final TaskRepositoryInterface taskRepo;
  final TaskController taskController;
  final SyncController syncController;
  final ReminderRepositoryInterface reminderRepo;
  final ReminderController reminderController;
  final NoteRepositoryInterface noteRepo;
  final NoteController noteController;
  final HabitRepositoryInterface habitRepo;
  final HabitLogRepositoryInterface habitLogRepo;
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
