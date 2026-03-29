import 'package:nexus/core/utils/conflict_detectable.dart';

/// Compares local vs remote note payloads for edit conflicts.

class NoteConflictDetector {
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
