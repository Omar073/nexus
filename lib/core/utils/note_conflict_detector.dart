import 'package:nexus/features/notes/models/note.dart';

class NoteConflictDetector {
  static bool hasConflict({required Note local, required Note remote}) {
    final localLastSync = local.lastSyncedAt;
    final localDirty = local.isDirty;
    final remoteNewerThanLocalSync =
        localLastSync != null && remote.updatedAt.isAfter(localLastSync);
    return localDirty && remoteNewerThanLocalSync;
  }
}
