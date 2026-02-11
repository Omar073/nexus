import 'dart:async';
import 'dart:io';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/features/tasks/controllers/task_controller_base.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/models/task_attachment.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';

/// Mixin containing CRUD operations for tasks.
mixin TaskCrudMixin on TaskControllerBase {
  Future<Task> createTask({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskDifficulty? difficulty,
    TaskRecurrenceRule recurrence = TaskRecurrenceRule.none,
    String? categoryId,
    String? subcategoryId,
  }) async {
    final now = DateTime.now();
    final task = Task(
      id: uuid.v4(),
      title: title.trim(),
      description: (description?.trim().isEmpty ?? true)
          ? null
          : description?.trim(),
      status: TaskStatus.active.index,
      createdAt: now,
      updatedAt: now,
      dueDate: dueDate,
      startDate: startDate,
      priority: priority?.index,
      difficulty: difficulty?.index,
      recurringRule: recurrence.index,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      lastModifiedByDevice: deviceId,
      isDirty: true,
      syncStatus: SyncStatus.idle.index,
    );
    await repo.upsert(task);
    await enqueueTaskUpsert(task, isCreate: true);
    return task;
  }

  Future<void> updateTask(
    Task task, {
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskDifficulty? difficulty,
    TaskRecurrenceRule? recurrence,
    String? categoryId,
    String? subcategoryId,
  }) async {
    final now = DateTime.now();
    if (title != null) task.title = title.trim();
    if (description != null) {
      task.description = description.trim().isEmpty ? null : description.trim();
    }
    if (startDate != null) task.startDate = startDate;
    if (dueDate != null) task.dueDate = dueDate;
    if (priority != null) task.priorityEnum = priority;
    if (difficulty != null) task.difficultyEnum = difficulty;
    if (recurrence != null) task.recurringRuleEnum = recurrence;
    if (categoryId != null) task.categoryId = categoryId;
    if (subcategoryId != null) task.subcategoryId = subcategoryId;
    task.updatedAt = now;
    task.lastModifiedByDevice = deviceId;
    task.isDirty = true;
    task.syncStatusEnum = SyncStatus.idle;
    await task.save();
    await enqueueTaskUpsert(task, isCreate: false);
  }

  @override
  Future<void> deleteTask(Task task) async {
    await repo.delete(task.id);
    final op = SyncOperation(
      id: uuid.v4(),
      type: SyncOperationType.delete.index,
      entityType: 'task',
      entityId: task.id,
      createdAt: DateTime.now(),
      data: null,
    );
    await syncService.enqueueOperation(op);
    unawaited(syncService.syncOnce());
  }

  Future<void> toggleCompleted(Task task, bool completed) async {
    final now = DateTime.now();
    task.statusEnum = completed ? TaskStatus.completed : TaskStatus.active;
    task.completedAt = completed ? now : null;
    task.updatedAt = now;
    task.lastModifiedByDevice = deviceId;
    task.isDirty = true;
    task.syncStatusEnum = SyncStatus.idle;
    await task.save();
    await enqueueTaskUpsert(task, isCreate: false);

    if (completed && task.recurringRuleEnum != TaskRecurrenceRule.none) {
      await _createNextRecurring(task);
    }
  }

  Future<void> addAttachment(Task task, TaskAttachment attachment) async {
    task.attachments = [...task.attachments, attachment];
    task.updatedAt = DateTime.now();
    task.lastModifiedByDevice = deviceId;
    task.isDirty = true;
    task.syncStatusEnum = SyncStatus.idle;
    await task.save();

    // Best-effort upload to Google Drive if authenticated + localUri exists.
    if (attachment.localUri != null) {
      try {
        final file = File(attachment.localUri!);
        if (await file.exists()) {
          final driveId = await googleDrive.uploadTaskFile(
            taskId: task.id,
            file: file,
            filename: file.uri.pathSegments.last,
            mimeType: attachment.mimeType,
          );
          attachment.driveFileId = driveId;
          attachment.uploaded = true;
          await task.save();
        }
      } catch (e) {
        rethrow;
      }
    }

    await enqueueTaskUpsert(task, isCreate: false);
  }

  Future<void> _createNextRecurring(Task completedTask) async {
    final rule = completedTask.recurringRuleEnum;
    final nextDue = switch (rule) {
      TaskRecurrenceRule.daily => (completedTask.dueDate ?? DateTime.now()).add(
        const Duration(days: 1),
      ),
      TaskRecurrenceRule.weekly =>
        (completedTask.dueDate ?? DateTime.now()).add(const Duration(days: 7)),
      _ => null,
    };
    if (nextDue == null) return;

    await createTask(
      title: completedTask.title,
      description: completedTask.description,
      dueDate: nextDue,
      priority: completedTask.priorityEnum,
      difficulty: completedTask.difficultyEnum,
      recurrence: completedTask.recurringRuleEnum,
    );
  }

  @override
  Future<void> enqueueTaskUpsert(Task task, {required bool isCreate}) async {
    final op = SyncOperation(
      id: uuid.v4(),
      type: (isCreate ? SyncOperationType.create : SyncOperationType.update)
          .index,
      entityType: 'task',
      entityId: task.id,
      createdAt: DateTime.now(),
      data: task.toFirestoreJson(),
    );
    await syncService.enqueueOperation(op);
    unawaited(syncService.syncOnce());
  }

  Future<void> saveTask(Task task) async {
    final now = DateTime.now();
    task.updatedAt = now;
    task.lastModifiedByDevice = deviceId;
    task.isDirty = true;
    task.syncStatusEnum = SyncStatus.idle;
    await task.save();
    await enqueueTaskUpsert(task, isCreate: false);
  }
}
