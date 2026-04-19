import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus/core/services/platform/backend_health_checker.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/notes/data/sync/note_sync_handler.dart';
import 'package:nexus/features/reminders/data/sync/reminder_sync_handler.dart';
import 'package:nexus/features/splash/presentation/models/app_initialization_result.dart';
import 'package:nexus/features/tasks/data/sync/task_sync_handler.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> createAppServiceProviders(
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
        return SyncService(
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
      },
    ),
    Provider<NotificationService>(
      create: (_) => fullResult != null
          ? fullResult.notificationService
          : NotificationService(),
    ),
    Provider<GoogleDriveService>(
      create: (_) => fullResult != null
          ? fullResult.googleDriveService
          : GoogleDriveService(),
    ),
    ProxyProvider<GoogleDriveService, BackendHealthChecker>(
      update: (_, driveService, _) =>
          BackendHealthChecker(googleDriveService: driveService),
    ),
  ];
}
