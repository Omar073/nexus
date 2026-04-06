import 'dart:async';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/notifications/reminder_notifications.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';
import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';

/// Edits fields and refreshes scheduling.

class UpdateReminderUseCase {
  UpdateReminderUseCase(this._repo, this._notifications, this._syncService);

  final ReminderRepositoryInterface _repo;
  final ReminderNotifications _notifications;
  final SyncService _syncService;

  Future<void> call(
    ReminderEntity reminder, {
    String? title,
    DateTime? time,
  }) async {
    final now = DateTime.now();
    final updated = ReminderEntity(
      id: reminder.id,
      taskId: reminder.taskId,
      title: (title ?? reminder.title).trim(),
      time: time ?? reminder.time,
      createdAt: reminder.createdAt,
      updatedAt: now,
      completedAt: reminder.completedAt,
      notificationId: reminder.notificationId,
      snoozeMinutes: reminder.snoozeMinutes,
      notifiedAt: time != null ? null : reminder.notifiedAt,
    );
    await _repo.upsert(updated);
    await _enqueueUpsert(updated);
    if (reminder.notificationId != null) {
      await _notifications.cancel(reminder.notificationId!);
    }
    await _notifications.schedule(
      id: updated.notificationId ?? 0,
      title: 'Reminder',
      body: updated.title,
      when: updated.time,
      payload: updated.id,
    );
  }

  Future<void> _enqueueUpsert(ReminderEntity reminder) async {
    final payload = _repo.getSyncPayload(reminder.id);
    if (payload == null) return;
    final op = SyncOperation(
      id: reminder.id,
      type: SyncOperationType.update.index,
      entityType: 'reminder',
      entityId: reminder.id,
      createdAt: DateTime.now(),
      data: payload,
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }
}
