import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/repositories/task_repository_interface.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';

/// Resolves a task conflict by accepting the remote snapshot locally.
class ResolveTaskConflictKeepRemoteUseCase {
  ResolveTaskConflictKeepRemoteUseCase(this._repo);

  final TaskRepositoryInterface _repo;

  Future<void> call(TaskEntity remote) async {
    final resolved = TaskEntity(
      id: remote.id,
      title: remote.title,
      description: remote.description,
      categoryId: remote.categoryId,
      subcategoryId: remote.subcategoryId,
      dueDate: remote.dueDate,
      priority: remote.priority,
      difficulty: remote.difficulty,
      status: remote.status,
      createdAt: remote.createdAt,
      updatedAt: remote.updatedAt,
      completedAt: remote.completedAt,
      recurringRule: remote.recurringRule,
      attachments: remote.attachments,
      isDirty: false,
      lastSyncedAt: DateTime.now(),
      syncStatus: SyncStatus.synced.index,
      lastModifiedByDevice: remote.lastModifiedByDevice,
      startDate: remote.startDate,
    );
    await _repo.upsert(resolved);
  }
}
