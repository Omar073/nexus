import 'package:nexus/features/tasks/domain/entities/task_attachment_entity.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/data/models/task.dart';
import 'package:nexus/features/tasks/data/models/task_attachment.dart';

/// Maps [Task] Hive model to domain entity and back.

class TaskMapper {
  static TaskEntity toEntity(Task t) {
    return TaskEntity(
      id: t.id,
      title: t.title,
      description: t.description,
      categoryId: t.categoryId,
      subcategoryId: t.subcategoryId,
      dueDate: t.dueDate,
      priority: t.priority,
      difficulty: t.difficulty,
      status: t.status,
      createdAt: t.createdAt,
      updatedAt: t.updatedAt,
      completedAt: t.completedAt,
      recurringRule: t.recurringRule,
      attachments: t.attachments.map(_attachmentToEntity).toList(),
      isDirty: t.isDirty,
      lastSyncedAt: t.lastSyncedAt,
      syncStatus: t.syncStatus,
      lastModifiedByDevice: t.lastModifiedByDevice,
      startDate: t.startDate,
    );
  }

  static TaskAttachmentEntity attachmentToEntity(TaskAttachment a) {
    return TaskAttachmentEntity(
      id: a.id,
      storagePath: a.storagePath,
      mimeType: a.mimeType,
      localUri: a.localUri,
      driveFileId: a.driveFileId,
      uploaded: a.uploaded,
      createdAt: a.createdAt,
    );
  }

  static TaskAttachmentEntity _attachmentToEntity(TaskAttachment a) =>
      attachmentToEntity(a);

  static Task toModel(TaskEntity e) {
    return Task(
      id: e.id,
      title: e.title,
      description: e.description,
      categoryId: e.categoryId,
      subcategoryId: e.subcategoryId,
      dueDate: e.dueDate,
      priority: e.priority,
      difficulty: e.difficulty,
      status: e.status,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      completedAt: e.completedAt,
      recurringRule: e.recurringRule,
      attachments: e.attachments.map(_attachmentToModel).toList(),
      isDirty: e.isDirty,
      lastSyncedAt: e.lastSyncedAt,
      syncStatus: e.syncStatus,
      lastModifiedByDevice: e.lastModifiedByDevice,
      startDate: e.startDate,
    );
  }

  static TaskAttachment _attachmentToModel(TaskAttachmentEntity a) {
    return TaskAttachment(
      id: a.id,
      storagePath: a.storagePath,
      mimeType: a.mimeType,
      localUri: a.localUri,
      driveFileId: a.driveFileId,
      uploaded: a.uploaded,
      createdAt: a.createdAt,
    );
  }
}
