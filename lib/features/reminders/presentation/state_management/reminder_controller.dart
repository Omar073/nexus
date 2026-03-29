import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:nexus/core/services/notifications/reminder_notifications.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';
import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';
import 'package:nexus/features/reminders/domain/use_cases/cleanup_completed_reminders_use_case.dart';
import 'package:nexus/features/reminders/domain/use_cases/complete_reminder_use_case.dart';
import 'package:nexus/features/reminders/domain/use_cases/create_reminder_use_case.dart';
import 'package:nexus/features/reminders/domain/use_cases/delete_reminder_use_case.dart';
import 'package:nexus/features/reminders/domain/use_cases/snooze_reminder_use_case.dart';
import 'package:nexus/features/reminders/domain/use_cases/uncomplete_reminder_use_case.dart';
import 'package:nexus/features/reminders/domain/use_cases/update_reminder_use_case.dart';
import 'package:nexus/features/reminders/data/services/reminder_timer_service.dart';

/// Reminder CRUD, list filters, bulk selection, and scheduling hooks.
/// Talks to [ReminderRepositoryImpl] and [NotificationService] for alarms.

class ReminderController extends ChangeNotifier {
  ReminderController({
    required ReminderRepositoryInterface repo,
    required ReminderNotifications notifications,
    required SyncService syncService,
  }) : _repo = repo,
       _timerService = ReminderTimerService(
         repo: repo,
         notifications: notifications,
       ),
       _create = CreateReminderUseCase(repo, notifications, syncService),
       _update = UpdateReminderUseCase(repo, notifications, syncService),
       _delete = DeleteReminderUseCase(repo, notifications, syncService),
       _complete = CompleteReminderUseCase(repo, notifications, syncService),
       _uncomplete = UncompleteReminderUseCase(
         repo,
         notifications,
         syncService,
       ),
       _snooze = SnoozeReminderUseCase(repo, notifications, syncService),
       _cleanup = CleanupCompletedRemindersUseCase(repo) {
    _subscription = repo.changes.listen((_) => notifyListeners());
    _cleanup.call();
    _timerService.start();
  }

  final ReminderRepositoryInterface _repo;
  final ReminderTimerService _timerService;
  final CreateReminderUseCase _create;
  final UpdateReminderUseCase _update;
  final DeleteReminderUseCase _delete;
  final CompleteReminderUseCase _complete;
  final UncompleteReminderUseCase _uncomplete;
  final SnoozeReminderUseCase _snooze;
  final CleanupCompletedRemindersUseCase _cleanup;
  StreamSubscription<void>? _subscription;

  @override
  void dispose() {
    _timerService.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  List<ReminderEntity> get reminders {
    final all = _repo.getAll().toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  List<ReminderEntity> get upcoming {
    final now = DateTime.now();
    return reminders
        .where((r) => r.completedAt == null && r.time.isAfter(now))
        .toList();
  }

  Future<ReminderEntity> create({
    required String title,
    required DateTime time,
    int? snoozeMinutes,
  }) async {
    final entity = await _create.call(
      title: title,
      time: time,
      snoozeMinutes: snoozeMinutes,
    );
    _timerService.scheduleNextCheck();
    return entity;
  }

  Future<void> update(
    ReminderEntity reminder, {
    String? title,
    DateTime? time,
  }) async {
    await _update.call(reminder, title: title, time: time);
    if (time != null) _timerService.resetFiredStatus(reminder.id);
    _timerService.scheduleNextCheck();
  }

  Future<void> delete(ReminderEntity reminder) async {
    await _delete.call(reminder);
    _timerService.scheduleNextCheck();
  }

  Future<void> complete(ReminderEntity reminder) async {
    await _complete.call(reminder);
    _timerService.scheduleNextCheck();
  }

  Future<void> uncomplete(ReminderEntity reminder) async {
    await _uncomplete.call(reminder);
    _timerService.resetFiredStatus(reminder.id);
    _timerService.scheduleNextCheck();
  }

  Future<void> snooze(ReminderEntity reminder, {int minutes = 5}) async {
    await _snooze.call(reminder, minutes: minutes);
    _timerService.resetFiredStatus(reminder.id);
    _timerService.scheduleNextCheck();
  }
}
