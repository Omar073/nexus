import 'dart:async';

import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/notifications/reminder_notifications.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';
import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';

/// Deletes a reminder locally and cancels notifications.

class DeleteReminderUseCase {
  DeleteReminderUseCase(this._repo, this._notifications, this._syncService);

  final ReminderRepositoryInterface _repo;
  final ReminderNotifications _notifications;
  final SyncService _syncService;

  Future<void> call(ReminderEntity reminder) async {
    if (reminder.notificationId != null) {
      await _notifications.cancel(reminder.notificationId!);
    }
    await _repo.delete(reminder.id);
    final op = SyncOperation(
      id: reminder.id,
      type: SyncOperationType.delete.index,
      entityType: 'reminder',
      entityId: reminder.id,
      createdAt: DateTime.now(),
    );
    await _syncService.enqueueOperation(op);
    unawaited(_syncService.syncOnce());
  }
}
