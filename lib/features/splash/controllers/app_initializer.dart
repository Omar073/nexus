import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/core/data/device_id_store.dart';
import 'package:nexus/core/data/hive/hive_bootstrap.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:nexus/core/services/platform/permission_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/core/services/notifications/workmanager_dispatcher.dart';
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
import 'package:nexus/firebase_setup/firebase_options.dart';
import 'package:workmanager/workmanager.dart';
import 'package:nexus/features/splash/models/initialization_results.dart';

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
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );

    // Initialize Hive
    await Hive.initFlutter();
    HiveBootstrap.registerAdapters();
    await HiveBootstrap.openBoxes();

    // Create or get device ID
    final deviceId = await DeviceIdStore().getOrCreate();

    // Load settings (needed for theme)
    final settingsController = SettingsController();
    await settingsController.load();

    // Initialize basic services
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
  ///
  /// Returns [AppInitializationResult] with all providers
  static Future<AppInitializationResult> completeInitialization(
    CriticalInitializationResult critical,
  ) async {
    // Initialize sync service
    final syncService = SyncService(
      firestore: FirebaseFirestore.instance,
      connectivity: critical.connectivityService,
      deviceId: critical.deviceId,
    );

    // Initialize notification service (can be slow)
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissionsIfNeeded();

    // Android-only: periodic background hook (can be slow)
    if (!kIsWeb && Platform.isAndroid) {
      await Workmanager().initialize(workmanagerCallbackDispatcher);
      await Workmanager().registerPeriodicTask(
        'nexus.periodic',
        'nexus.periodic',
        frequency: const Duration(minutes: 15),
      );
    }

    // Initialize Google Drive service (lazy-loaded when needed)
    final googleDriveService = GoogleDriveService();

    // Initialize repositories (lightweight, but can be deferred)
    final taskRepo = TaskRepository();
    final reminderRepo = ReminderRepository();
    final noteRepo = NoteRepository();
    final habitRepo = HabitRepository();
    final habitLogRepo = HabitLogRepository();

    // Initialize controllers (can be deferred until screens are accessed)
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
