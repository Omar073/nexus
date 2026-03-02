import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/core/data/device_id_store.dart';
import 'package:nexus/app/bootstrap/hive_bootstrap.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:nexus/core/services/platform/permission_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/reminders/data/services/reminder_workmanager_callback.dart';
import 'package:nexus/features/analytics/presentation/state_management/analytics_controller.dart';
import 'package:nexus/features/calendar/presentation/state_management/calendar_controller.dart';
import 'package:nexus/features/habits/presentation/state_management/habit_controller.dart';
import 'package:nexus/features/habits/data/repositories/habit_log_repository_impl.dart';
import 'package:nexus/features/habits/data/repositories/habit_repository_impl.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/notes/data/repositories/note_repository_impl.dart';
import 'package:nexus/features/reminders/presentation/state_management/reminder_controller.dart';
import 'package:nexus/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:nexus/features/reminders/data/sync/reminder_sync_handler.dart';
import 'package:nexus/features/habits/data/sync/habit_sync_handler.dart';
import 'package:nexus/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/sync/presentation/state_management/sync_controller.dart';
import 'package:nexus/features/tasks/presentation/state_management/task_controller.dart';
import 'package:nexus/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:nexus/features/tasks/data/sync/task_sync_handler.dart';
import 'package:nexus/features/notes/data/sync/note_sync_handler.dart';
import 'package:nexus/firebase_setup/firebase_options.dart';
import 'package:workmanager/workmanager.dart';
import 'package:nexus/features/splash/presentation/models/app_initialization_result.dart';
import 'package:nexus/features/splash/presentation/models/critical_initialization_result.dart';

/// Service responsible for initializing app dependencies
class AppInitializer {
  /// Initializes only critical services needed for the app to open
  ///
  /// This includes:
  /// - Firebase initialization
  /// - Hive initialization
  /// - Device ID
  /// - Settings controller (needed for theme)
  /// - Basic services (connectivity, permissions)
  ///
  /// Returns [CriticalInitializationResult] with minimal providers
  /// Throws if critical initialization fails
  static Future<CriticalInitializationResult> initializeCritical() async {
    // Only initialize if not already done (e.g. native auto-init or hot restart)
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );

    await Hive.initFlutter();
    HiveBootstrap.registerAdapters();
    await HiveBootstrap.openBoxes();

    final deviceId = await DeviceIdStore().getOrCreate();

    final settingsRepo = SettingsRepositoryImpl();
    final settingsController = SettingsController(settingsRepo);
    await settingsController.load();

    final connectivityService = ConnectivityService();
    final permissionService = PermissionService();

    return CriticalInitializationResult(
      settingsController: settingsController,
      deviceId: deviceId,
      connectivityService: connectivityService,
      permissionService: permissionService,
    );
  }

  /// Completes initialization of non-critical services in the background
  ///
  /// This should be called after the app has opened and splash screen is dismissed.
  /// Initializes:
  /// - Notification service
  /// - Workmanager (Android)
  /// - Google Drive service
  /// - All repositories
  /// - All controllers
  static Future<AppInitializationResult> completeInitialization(
    CriticalInitializationResult critical,
  ) async {
    final taskHandler = TaskSyncHandler(
      firestore: FirebaseFirestore.instance,
      deviceId: critical.deviceId,
    );

    final noteHandler = NoteSyncHandler(
      firestore: FirebaseFirestore.instance,
      deviceId: critical.deviceId,
    );

    final reminderHandler = ReminderSyncHandler(
      firestore: FirebaseFirestore.instance,
    );

    final habitHandler = HabitSyncHandler(
      firestore: FirebaseFirestore.instance,
    );

    final syncService = SyncService(
      connectivity: critical.connectivityService,
      handlers: [taskHandler, noteHandler, reminderHandler, habitHandler],
    );

    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissionsIfNeeded();

    if (!kIsWeb && Platform.isAndroid) {
      await Workmanager().initialize(reminderWorkmanagerCallbackDispatcher);
      await Workmanager().registerPeriodicTask(
        'nexus.periodic',
        'nexus.periodic',
        frequency: const Duration(minutes: 15),
      );
    }

    final googleDriveService = GoogleDriveService();

    final taskRepo = TaskRepositoryImpl();
    final reminderRepo = ReminderRepositoryImpl();
    final noteRepo = NoteRepositoryImpl();
    final habitRepo = HabitRepositoryImpl();
    final habitLogRepo = HabitLogRepositoryImpl();

    final taskController = TaskController(
      repo: taskRepo,
      syncService: syncService,
      googleDrive: googleDriveService,
      settings: critical.settingsController,
      deviceId: critical.deviceId,
    );

    final syncController = SyncController(syncService: syncService);

    final reminderController = ReminderController(
      repo: reminderRepo,
      notifications: notificationService,
      syncService: syncService,
    );

    final noteController = NoteController(
      repo: noteRepo,
      syncService: syncService,
      googleDrive: googleDriveService,
      deviceId: critical.deviceId,
    );

    final habitController = HabitController(
      habits: habitRepo,
      logs: habitLogRepo,
      syncService: syncService,
    );

    final analyticsController = AnalyticsController(
      tasks: taskController,
      reminders: reminderController,
      habits: habitController,
    );

    final calendarController = CalendarController(
      tasks: taskController,
      reminders: reminderController,
    );

    return AppInitializationResult(
      settingsController: critical.settingsController,
      deviceId: critical.deviceId,
      connectivityService: critical.connectivityService,
      syncService: syncService,
      notificationService: notificationService,
      permissionService: critical.permissionService,
      googleDriveService: googleDriveService,
      taskRepo: taskRepo,
      taskController: taskController,
      syncController: syncController,
      reminderRepo: reminderRepo,
      reminderController: reminderController,
      noteRepo: noteRepo,
      noteController: noteController,
      habitRepo: habitRepo,
      habitLogRepo: habitLogRepo,
      habitController: habitController,
      analyticsController: analyticsController,
      calendarController: calendarController,
    );
  }
}
