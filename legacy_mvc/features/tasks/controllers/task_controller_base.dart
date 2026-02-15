import 'package:flutter/foundation.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_repository.dart';
import 'package:uuid/uuid.dart';

/// Base class exposing dependencies to mixins.
abstract class TaskControllerBase extends ChangeNotifier {
  TaskRepository get repo;
  SyncService get syncService;
  GoogleDriveService get googleDrive;
  SettingsController get settings;
  String get deviceId;
  Uuid get uuid;

  Future<void> enqueueTaskUpsert(Task task, {required bool isCreate});
  Future<void> deleteTask(Task task);
}
