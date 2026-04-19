import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/analytics/presentation/state_management/analytics_controller.dart';
import 'package:nexus/features/calendar/presentation/state_management/calendar_controller.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/habits/data/repositories/habit_log_repository_impl.dart';
import 'package:nexus/features/habits/data/repositories/habit_repository_impl.dart';
import 'package:nexus/features/habits/domain/repositories/habit_log_repository_interface.dart';
import 'package:nexus/features/habits/domain/repositories/habit_repository_interface.dart';
import 'package:nexus/features/habits/presentation/state_management/habit_controller.dart';
import 'package:nexus/features/notes/data/repositories/note_repository_impl.dart';
import 'package:nexus/features/notes/data/sync/note_sync_handler.dart';
import 'package:nexus/features/notes/domain/repositories/note_repository_interface.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:nexus/features/reminders/data/sync/reminder_sync_handler.dart';
import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';
import 'package:nexus/features/reminders/presentation/state_management/reminder_controller.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/splash/presentation/models/app_initialization_result.dart';
import 'package:nexus/features/sync/presentation/state_management/sync_controller.dart';
import 'package:nexus/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:nexus/features/tasks/data/sync/task_sync_handler.dart';
import 'package:nexus/features/tasks/domain/repositories/task_repository_interface.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> createAppControllerProviders(
  SettingsController settings,
  ConnectivityService connectivity,
  String deviceId,
  AppInitializationResult? fullResult,
) {
  return [
    ChangeNotifierProvider(create: (_) => CategoryController()),
    _createTaskControllerProvider(settings, connectivity, deviceId, fullResult),
    _createSyncControllerProvider(connectivity, deviceId, fullResult),
    _createReminderControllerProvider(fullResult),
    _createNoteControllerProvider(connectivity, deviceId, fullResult),
    _createHabitControllerProvider(fullResult),
    _createAnalyticsControllerProvider(
      settings,
      connectivity,
      deviceId,
      fullResult,
    ),
    _createCalendarControllerProvider(
      settings,
      connectivity,
      deviceId,
      fullResult,
    ),
  ];
}

SingleChildWidget _createTaskControllerProvider(
  SettingsController settings,
  ConnectivityService connectivity,
  String deviceId,
  AppInitializationResult? fullResult,
) {
  return ChangeNotifierProxyProvider4<
    SettingsController,
    TaskRepositoryInterface,
    SyncService,
    GoogleDriveService,
    TaskController
  >(
    create: (_) {
      if (fullResult != null) return fullResult.taskController;
      return TaskController(
        repo: TaskRepositoryImpl(),
        syncService: SyncService(
          connectivity: connectivity,
          handlers: [
            TaskSyncHandler(
              firestore: FirebaseFirestore.instance,
              deviceId: deviceId,
            ),
            NoteSyncHandler(
              firestore: FirebaseFirestore.instance,
              deviceId: deviceId,
            ),
          ],
        ),
        googleDrive: GoogleDriveService(),
        settings: settings,
        deviceId: deviceId,
      );
    },
    update: (_, settings, taskRepo, syncService, googleDrive, previous) {
      if (fullResult != null) return fullResult.taskController;
      if (previous != null) return previous;
      return TaskController(
        repo: taskRepo,
        syncService: syncService,
        googleDrive: googleDrive,
        settings: settings,
        deviceId: deviceId,
      );
    },
  );
}

SingleChildWidget _createSyncControllerProvider(
  ConnectivityService connectivity,
  String deviceId,
  AppInitializationResult? fullResult,
) {
  return ChangeNotifierProxyProvider<SyncService, SyncController>(
    create: (_) {
      if (fullResult != null) return fullResult.syncController;
      return SyncController(
        syncService: SyncService(
          connectivity: connectivity,
          handlers: [
            TaskSyncHandler(
              firestore: FirebaseFirestore.instance,
              deviceId: deviceId,
            ),
            NoteSyncHandler(
              firestore: FirebaseFirestore.instance,
              deviceId: deviceId,
            ),
            ReminderSyncHandler(firestore: FirebaseFirestore.instance),
          ],
        ),
      );
    },
    update: (_, syncService, previous) {
      if (fullResult != null) return fullResult.syncController;
      if (previous != null) return previous;
      return SyncController(syncService: syncService);
    },
  );
}

SingleChildWidget _createReminderControllerProvider(
  AppInitializationResult? fullResult,
) {
  return ChangeNotifierProxyProvider3<
    ReminderRepositoryInterface,
    SyncService,
    NotificationService,
    ReminderController
  >(
    create: (_) {
      if (fullResult != null) return fullResult.reminderController;
      return ReminderController(
        repo: ReminderRepositoryImpl(),
        syncService: SyncService(
          connectivity: ConnectivityService(),
          handlers: [
            TaskSyncHandler(
              firestore: FirebaseFirestore.instance,
              deviceId: 'unknown',
            ),
            NoteSyncHandler(
              firestore: FirebaseFirestore.instance,
              deviceId: 'unknown',
            ),
            ReminderSyncHandler(firestore: FirebaseFirestore.instance),
          ],
        ),
        notifications: NotificationService(),
      );
    },
    update: (_, reminderRepo, syncService, notifications, previous) {
      if (fullResult != null) return fullResult.reminderController;
      if (previous != null) return previous;
      return ReminderController(
        repo: reminderRepo,
        syncService: syncService,
        notifications: notifications,
      );
    },
  );
}

SingleChildWidget _createNoteControllerProvider(
  ConnectivityService connectivity,
  String deviceId,
  AppInitializationResult? fullResult,
) {
  return ChangeNotifierProxyProvider3<
    NoteRepositoryInterface,
    SyncService,
    GoogleDriveService,
    NoteController
  >(
    create: (_) {
      if (fullResult != null) return fullResult.noteController;
      return NoteController(
        repo: NoteRepositoryImpl(),
        syncService: SyncService(
          connectivity: connectivity,
          handlers: [
            TaskSyncHandler(
              firestore: FirebaseFirestore.instance,
              deviceId: deviceId,
            ),
            NoteSyncHandler(
              firestore: FirebaseFirestore.instance,
              deviceId: deviceId,
            ),
          ],
        ),
        googleDrive: GoogleDriveService(),
        deviceId: deviceId,
      );
    },
    update: (_, noteRepo, syncService, googleDrive, previous) {
      if (fullResult != null) return fullResult.noteController;
      if (previous != null) return previous;
      return NoteController(
        repo: noteRepo,
        syncService: syncService,
        googleDrive: googleDrive,
        deviceId: deviceId,
      );
    },
  );
}

SingleChildWidget _createHabitControllerProvider(
  AppInitializationResult? fullResult,
) {
  return ChangeNotifierProxyProvider3<
    HabitRepositoryInterface,
    HabitLogRepositoryInterface,
    SyncService,
    HabitController
  >(
    create: (_) {
      if (fullResult != null) return fullResult.habitController;
      return HabitController(
        habits: HabitRepositoryImpl(),
        logs: HabitLogRepositoryImpl(),
        syncService: SyncService(
          connectivity: ConnectivityService(),
          handlers: const [],
        ),
      );
    },
    update: (_, habitRepo, habitLogRepo, syncService, previous) {
      if (fullResult != null) return fullResult.habitController;
      if (previous != null) return previous;
      return HabitController(
        habits: habitRepo,
        logs: habitLogRepo,
        syncService: syncService,
      );
    },
  );
}

SingleChildWidget _createAnalyticsControllerProvider(
  SettingsController settings,
  ConnectivityService connectivity,
  String deviceId,
  AppInitializationResult? fullResult,
) {
  return ChangeNotifierProxyProvider3<
    TaskController,
    ReminderController,
    HabitController,
    AnalyticsController
  >(
    create: (_) {
      if (fullResult != null) return fullResult.analyticsController;
      final syncService = SyncService(
        connectivity: connectivity,
        handlers: [
          TaskSyncHandler(
            firestore: FirebaseFirestore.instance,
            deviceId: deviceId,
          ),
          NoteSyncHandler(
            firestore: FirebaseFirestore.instance,
            deviceId: deviceId,
          ),
          ReminderSyncHandler(firestore: FirebaseFirestore.instance),
        ],
      );
      final reminders = ReminderController(
        repo: ReminderRepositoryImpl(),
        notifications: NotificationService(),
        syncService: syncService,
      );
      final tasks = TaskController(
        repo: TaskRepositoryImpl(),
        syncService: syncService,
        googleDrive: GoogleDriveService(),
        settings: settings,
        deviceId: deviceId,
      );
      final habits = HabitController(
        habits: HabitRepositoryImpl(),
        logs: HabitLogRepositoryImpl(),
        syncService: syncService,
      );
      return AnalyticsController(
        tasks: tasks,
        reminders: reminders,
        habits: habits,
      );
    },
    update: (_, tasks, reminders, habits, previous) {
      if (fullResult != null) return fullResult.analyticsController;
      if (previous != null) return previous;
      return AnalyticsController(
        tasks: tasks,
        reminders: reminders,
        habits: habits,
      );
    },
  );
}

SingleChildWidget _createCalendarControllerProvider(
  SettingsController settings,
  ConnectivityService connectivity,
  String deviceId,
  AppInitializationResult? fullResult,
) {
  return ChangeNotifierProxyProvider2<
    TaskController,
    ReminderController,
    CalendarController
  >(
    create: (_) {
      if (fullResult != null) return fullResult.calendarController;
      final syncService = SyncService(
        connectivity: connectivity,
        handlers: [
          TaskSyncHandler(
            firestore: FirebaseFirestore.instance,
            deviceId: deviceId,
          ),
          NoteSyncHandler(
            firestore: FirebaseFirestore.instance,
            deviceId: deviceId,
          ),
          ReminderSyncHandler(firestore: FirebaseFirestore.instance),
        ],
      );
      final reminders = ReminderController(
        repo: ReminderRepositoryImpl(),
        notifications: NotificationService(),
        syncService: syncService,
      );
      final tasks = TaskController(
        repo: TaskRepositoryImpl(),
        syncService: syncService,
        googleDrive: GoogleDriveService(),
        settings: settings,
        deviceId: deviceId,
      );
      return CalendarController(tasks: tasks, reminders: reminders);
    },
    update: (_, tasks, reminders, previous) {
      if (fullResult != null) return fullResult.calendarController;
      if (previous != null) return previous;
      return CalendarController(tasks: tasks, reminders: reminders);
    },
  );
}
