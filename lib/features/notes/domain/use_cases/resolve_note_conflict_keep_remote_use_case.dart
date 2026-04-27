import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/domain/repositories/note_repository_interface.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';

/// Resolves a note conflict by accepting the remote snapshot locally.
class ResolveNoteConflictKeepRemoteUseCase {
  ResolveNoteConflictKeepRemoteUseCase(this._repo);

  final NoteRepositoryInterface _repo;

  Future<void> call(NoteEntity remote) async {
    final resolved = NoteEntity(
      id: remote.id,
      title: remote.title,
      contentDeltaJson: remote.contentDeltaJson,
      createdAt: remote.createdAt,
      updatedAt: remote.updatedAt,
      lastModifiedByDevice: remote.lastModifiedByDevice,
      attachments: remote.attachments,
      isDirty: false,
      lastSyncedAt: DateTime.now(),
      syncStatus: SyncStatus.synced.index,
      categoryId: remote.categoryId,
      isMarkdown: remote.isMarkdown,
    );
    await _repo.upsert(resolved);
  }
}
