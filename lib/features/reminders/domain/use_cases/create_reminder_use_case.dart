import 'dart:async';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/notifications/reminder_notifications.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';
import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';
import 'package:uuid/uuid.dart';

/// Creates a reminder and schedules notifications.

class CreateReminderUseCase {
  CreateReminderUseCase(
    this._repo,
    this._notifications,
    this._syncService, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final ReminderRepositoryInterface _repo;
  final ReminderNotifications _notifications;
  final SyncService _syncService;
  final Uuid _uuid;

  Future<ReminderEntity> call({
    required String title,
    required DateTime time,
    int? snoozeMinutes,
  }) async {
    final now = DateTime.now();
    final notificationId = now.microsecondsSinceEpoch.remainder(1 << 31);
    final entity = ReminderEntity(
      id: _uuid.v4(),
      taskId: '',
      title: title.trim(),
      time: time,
      snoozeMinutes: snoozeMinutes,
      createdAt: now,
      updatedAt: now,
      notificationId: notificationId,
    );
    await _repo.upsert(entity);
    await _enqueueUpsert(entity, isCreate: true);
    await _notifications.schedule(
      id: notificationId,
      title: 'Reminder',
      body: entity.title,
      when: entity.time,
      payload: entity.id,
    );
    return entity;
  }

  Future<void> _enqueueUpsert(
    ReminderEntity reminder, {
    required bool isCreate,
  }) async {
    final payload = _repo.getSyncPayload(reminder.id);
    if (payload == null) return;
    final op = SyncOperation(
      id: _uuid.v4(),
      type: (isCreate ? SyncOperationType.create : SyncOperationType.update)
          .index,
      entityType: 'reminder',
      entityId: reminder.id,
      createdAt: DateTime.now(),
      data: payload,
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }
}
