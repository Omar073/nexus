import 'package:nexus/features/tasks/models/task.dart';

class TaskConflictDetector {
  static bool hasConflict({required Task local, required Task remote}) {
    final localLastSync = local.lastSyncedAt;
    final localDirty = local.isDirty;
    final remoteNewerThanLocalSync =
        localLastSync != null && remote.updatedAt.isAfter(localLastSync);
    return localDirty && remoteNewerThanLocalSync;
  }
}


