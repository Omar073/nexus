import 'package:nexus/core/utils/conflict_detectable.dart';

/// Conflict detection for reminders.
///
/// Same strategy as tasks/notes:
/// - Conflict exists if we have unsynced local changes (isDirty == true)
/// - AND the remote version's updatedAt is newer than our last successful sync.
class ReminderConflictDetector {
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
