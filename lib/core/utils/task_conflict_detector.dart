import 'package:nexus/core/utils/conflict_detectable.dart';

class TaskConflictDetector {
  static bool hasConflict({
    required ConflictDetectable local,
    required ConflictDetectable remote,
  }) {
    final localLastSync = local.lastSyncedAt;
    final localDirty = local.isDirty;
    final remoteNewerThanLocalSync =
        localLastSync != null && remote.updatedAt.isAfter(localLastSync);
    return localDirty && remoteNewerThanLocalSync;
  }
}
