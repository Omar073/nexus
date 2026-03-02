import 'dart:async';
import 'dart:io';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/storage/google_drive_service.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/tasks/domain/entities/task_attachment_entity.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/repositories/task_repository_interface.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:uuid/uuid.dart';

class AddTaskAttachmentUseCase {
  AddTaskAttachmentUseCase(
    this._repo,
    this._syncService,
    this._googleDrive, {
    required String deviceId,
    Uuid? uuid,
  }) : _deviceId = deviceId,
       _uuid = uuid ?? const Uuid();

  final TaskRepositoryInterface _repo;
  final SyncService _syncService;
  final GoogleDriveService _googleDrive;
  final String _deviceId;
  final Uuid _uuid;

  Future<void> call(TaskEntity task, TaskAttachmentEntity attachment) async {
    var attachmentList = [...task.attachments, attachment];
    var updated = TaskEntity(
      id: task.id,
      title: task.title,
      description: task.description,
      categoryId: task.categoryId,
      subcategoryId: task.subcategoryId,
      dueDate: task.dueDate,
      startDate: task.startDate,
      priority: task.priority,
      difficulty: task.difficulty,
      status: task.status,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
      completedAt: task.completedAt,
      recurringRule: task.recurringRule,
      attachments: attachmentList,
      isDirty: true,
      lastSyncedAt: task.lastSyncedAt,
      syncStatus: SyncStatus.idle.index,
      lastModifiedByDevice: _deviceId,
    );
    await _repo.upsert(updated);

    if (attachment.localUri != null && attachment.localUri!.isNotEmpty) {
      try {
        final file = File(attachment.localUri!);
        if (await file.exists()) {
          final driveId = await _googleDrive.uploadTaskFile(
            taskId: task.id,
            file: file,
            filename: file.uri.pathSegments.last,
            mimeType: attachment.mimeType,
          );
          final uploadedAtt = TaskAttachmentEntity(
            id: attachment.id,
            storagePath: attachment.storagePath,
            mimeType: attachment.mimeType,
            localUri: attachment.localUri,
            driveFileId: driveId,
            uploaded: true,
            createdAt: attachment.createdAt,
          );
          attachmentList = [...task.attachments, uploadedAtt];
          updated = TaskEntity(
            id: task.id,
            title: task.title,
            description: task.description,
            categoryId: task.categoryId,
            subcategoryId: task.subcategoryId,
            dueDate: task.dueDate,
            startDate: task.startDate,
            priority: task.priority,
            difficulty: task.difficulty,
            status: task.status,
            createdAt: task.createdAt,
            updatedAt: DateTime.now(),
            completedAt: task.completedAt,
            recurringRule: task.recurringRule,
            attachments: attachmentList,
            isDirty: true,
            lastSyncedAt: task.lastSyncedAt,
            syncStatus: SyncStatus.idle.index,
            lastModifiedByDevice: _deviceId,
          );
          await _repo.upsert(updated);
        }
      } catch (e) {
        rethrow;
      }
    }

    await _enqueueUpsert(updated);
  }

  Future<void> _enqueueUpsert(TaskEntity task) async {
    final payload = _repo.getSyncPayload(task.id);
    if (payload == null) return;
    final op = SyncOperation(
      id: _uuid.v4(),
      type: SyncOperationType.update.index,
      entityType: 'task',
      entityId: task.id,
      createdAt: DateTime.now(),
      data: payload,
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }
}
