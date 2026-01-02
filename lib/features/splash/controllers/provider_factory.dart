import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:nexus/core/services/platform/permission_service.dart';
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
import 'package:nexus/features/tasks/controllers/category_controller.dart';
import 'package:nexus/features/tasks/models/task_repository.dart';
import 'package:nexus/features/splash/models/initialization_results.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Factory for creating app providers from initialization results
class AppProviderFactory {
  /// Creates providers from critical initialization result
  ///
  /// Returns a list of providers that can be used with MultiProvider.
  /// Non-critical providers are created lazily and will be updated when
  /// full initialization completes.
  static List<SingleChildWidget> createProviders(
    CriticalInitializationResult critical,
    AppInitializationResult? fullResult,
  ) {
    // Store references for use in lazy providers
    final settings = critical.settingsController;
    final connectivity = critical.connectivityService;
    final device = critical.deviceId;

    // Critical providers (always available)
    final criticalProviders = <SingleChildWidget>[
      ChangeNotifierProvider.value(value: settings),
      Provider<String>.value(value: device),
      Provider<ConnectivityService>.value(value: connectivity),
      Provider<PermissionService>.value(value: critical.permissionService),
    ];

    // Non-critical providers (lazy initialization)
    final lazyProviders = <SingleChildWidget>[
      ..._createServiceProviders(connectivity, device, fullResult),
      ..._createRepositoryProviders(fullResult),
      ..._createControllerProviders(settings, connectivity, device, fullResult),
    ];

    return [...criticalProviders, ...lazyProviders];
  }

  /// Creates service providers (SyncService, NotificationService, GoogleDriveService)
  static List<SingleChildWidget> _createServiceProviders(
    ConnectivityService connectivity,
    String deviceId,
    AppInitializationResult? fullResult,
  ) {
    return [
      ProxyProvider<ConnectivityService, SyncService>(
        update: (_, connectivity, _) {
          if (fullResult != null) {
            return fullResult.syncService;
          }
          // Create a minimal sync service for now (will be replaced)
          return SyncService(
            firestore: FirebaseFirestore.instance,
            connectivity: connectivity,
            deviceId: deviceId,
          );
        },
      ),
      Provider<NotificationService>(
        create: (_) {
          if (fullResult != null) {
            return fullResult.notificationService;
          }
          // Create uninitialized service (will initialize in background)
          return NotificationService();
        },
      ),
      Provider<GoogleDriveService>(
        create: (_) {
          if (fullResult != null) {
            return fullResult.googleDriveService;
          }
          return GoogleDriveService();
        },
      ),
    ];
  }

  /// Creates repository providers
  static List<SingleChildWidget> _createRepositoryProviders(
    AppInitializationResult? fullResult,
  ) {
    return [
      Provider<TaskRepository>(
        create: (_) => fullResult?.taskRepo ?? TaskRepository(),
      ),
      Provider<ReminderRepository>(
        create: (_) => fullResult?.reminderRepo ?? ReminderRepository(),
      ),
      Provider<NoteRepository>(
        create: (_) => fullResult?.noteRepo ?? NoteRepository(),
      ),
      Provider<HabitRepository>(
        create: (_) => fullResult?.habitRepo ?? HabitRepository(),
      ),
      Provider<HabitLogRepository>(
        create: (_) => fullResult?.habitLogRepo ?? HabitLogRepository(),
      ),
    ];
  }

  /// Creates controller providers (all extend ChangeNotifier)
  static List<SingleChildWidget> _createControllerProviders(
    SettingsController settings,
    ConnectivityService connectivity,
    String deviceId,
    AppInitializationResult? fullResult,
  ) {
    return [
      // CategoryController - simple provider, no dependencies
      ChangeNotifierProvider(create: (_) => CategoryController()),
      _createTaskControllerProvider(
        settings,
        connectivity,
        deviceId,
        fullResult,
      ),
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

  static SingleChildWidget _createTaskControllerProvider(
    SettingsController settings,
    ConnectivityService connectivity,
    String deviceId,
    AppInitializationResult? fullResult,
  ) {
    return ChangeNotifierProxyProvider4<
      SettingsController,
      TaskRepository,
      SyncService,
      GoogleDriveService,
      TaskController
    >(
      create: (_) {
        if (fullResult != null) {
          return fullResult.taskController;
        }
        // Create minimal controller (will be replaced when full init completes)
        return TaskController(
          repo: TaskRepository(),
          syncService: SyncService(
            firestore: FirebaseFirestore.instance,
            connectivity: connectivity,
            deviceId: deviceId,
          ),
          googleDrive: GoogleDriveService(),
          settings: settings,
          deviceId: deviceId,
        );
      },
      update: (_, settings, taskRepo, syncService, googleDrive, previous) {
        if (fullResult != null) {
          return fullResult.taskController;
        }
        // Reuse previous instance if dependencies haven't changed
        if (previous != null) {
          return previous;
        }
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

  static SingleChildWidget _createSyncControllerProvider(
    ConnectivityService connectivity,
    String deviceId,
    AppInitializationResult? fullResult,
  ) {
    return ChangeNotifierProxyProvider<SyncService, SyncController>(
      create: (_) {
        if (fullResult != null) {
          return fullResult.syncController;
        }
        return SyncController(
          syncService: SyncService(
            firestore: FirebaseFirestore.instance,
            connectivity: connectivity,
            deviceId: deviceId,
          ),
        );
      },
      update: (_, syncService, previous) {
        if (fullResult != null) {
          return fullResult.syncController;
        }
        // Reuse previous instance if service hasn't changed
        if (previous != null) {
          return previous;
        }
        return SyncController(syncService: syncService);
      },
    );
  }

  static SingleChildWidget _createReminderControllerProvider(
    AppInitializationResult? fullResult,
  ) {
    return ChangeNotifierProxyProvider2<
      ReminderRepository,
      NotificationService,
      ReminderController
    >(
      create: (_) {
        if (fullResult != null) {
          return fullResult.reminderController;
        }
        return ReminderController(
          repo: ReminderRepository(),
          notifications: NotificationService(),
        );
      },
      update: (_, reminderRepo, notifications, previous) {
        if (fullResult != null) {
          return fullResult.reminderController;
        }
        if (previous != null) {
          return previous;
        }
        return ReminderController(
          repo: reminderRepo,
          notifications: notifications,
        );
      },
    );
  }

  static SingleChildWidget _createNoteControllerProvider(
    ConnectivityService connectivity,
    String deviceId,
    AppInitializationResult? fullResult,
  ) {
    return ChangeNotifierProxyProvider3<
      NoteRepository,
      SyncService,
      GoogleDriveService,
      NoteController
    >(
      create: (_) {
        if (fullResult != null) {
          return fullResult.noteController;
        }
        return NoteController(
          repo: NoteRepository(),
          syncService: SyncService(
            firestore: FirebaseFirestore.instance,
            connectivity: connectivity,
            deviceId: deviceId,
          ),
          googleDrive: GoogleDriveService(),
          deviceId: deviceId,
        );
      },
      update: (_, noteRepo, syncService, googleDrive, previous) {
        if (fullResult != null) {
          return fullResult.noteController;
        }
        if (previous != null) {
          return previous;
        }
        return NoteController(
          repo: noteRepo,
          syncService: syncService,
          googleDrive: googleDrive,
          deviceId: deviceId,
        );
      },
    );
  }

  static SingleChildWidget _createHabitControllerProvider(
    AppInitializationResult? fullResult,
  ) {
    return ChangeNotifierProxyProvider2<
      HabitRepository,
      HabitLogRepository,
      HabitController
    >(
      create: (_) {
        if (fullResult != null) {
          return fullResult.habitController;
        }
        return HabitController(
          habits: HabitRepository(),
          logs: HabitLogRepository(),
        );
      },
      update: (_, habitRepo, habitLogRepo, previous) {
        if (fullResult != null) {
          return fullResult.habitController;
        }
        if (previous != null) {
          return previous;
        }
        return HabitController(habits: habitRepo, logs: habitLogRepo);
      },
    );
  }

  static SingleChildWidget _createAnalyticsControllerProvider(
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
        if (fullResult != null) {
          return fullResult.analyticsController;
        }
        return AnalyticsController(
          tasks: TaskController(
            repo: TaskRepository(),
            syncService: SyncService(
              firestore: FirebaseFirestore.instance,
              connectivity: connectivity,
              deviceId: deviceId,
            ),
            googleDrive: GoogleDriveService(),
            settings: settings,
            deviceId: deviceId,
          ),
          reminders: ReminderController(
            repo: ReminderRepository(),
            notifications: NotificationService(),
          ),
          habits: HabitController(
            habits: HabitRepository(),
            logs: HabitLogRepository(),
          ),
        );
      },
      update: (_, tasks, reminders, habits, previous) {
        if (fullResult != null) {
          return fullResult.analyticsController;
        }
        if (previous != null) {
          return previous;
        }
        return AnalyticsController(
          tasks: tasks,
          reminders: reminders,
          habits: habits,
        );
      },
    );
  }

  static SingleChildWidget _createCalendarControllerProvider(
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
        if (fullResult != null) {
          return fullResult.calendarController;
        }
        return CalendarController(
          tasks: TaskController(
            repo: TaskRepository(),
            syncService: SyncService(
              firestore: FirebaseFirestore.instance,
              connectivity: connectivity,
              deviceId: deviceId,
            ),
            googleDrive: GoogleDriveService(),
            settings: settings,
            deviceId: deviceId,
          ),
          reminders: ReminderController(
            repo: ReminderRepository(),
            notifications: NotificationService(),
          ),
        );
      },
      update: (_, tasks, reminders, previous) {
        if (fullResult != null) {
          return fullResult.calendarController;
        }
        if (previous != null) {
          return previous;
        }
        return CalendarController(tasks: tasks, reminders: reminders);
      },
    );
  }
}
