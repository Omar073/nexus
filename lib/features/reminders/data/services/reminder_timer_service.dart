import 'dart:async';

import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:nexus/core/services/notifications/reminder_notifications.dart';
import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';
import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';

/// Service responsible for managing the in-app timer for reminders.
/// It supports multiple strategies (Smart Timer vs Polling).
class ReminderTimerService {
  ReminderTimerService({
    required ReminderRepositoryInterface repo,
    required ReminderNotifications notifications,
  }) : _repo = repo,
       _notifications = notifications;

  final ReminderRepositoryInterface _repo;
  final ReminderNotifications _notifications;

  Timer? _reminderCheckTimer;
  Timer? _smartTimer;
  final Set<String> _firedReminderIds = {};

  void start() {
    scheduleNextCheck();
  }

  void dispose() {
    _reminderCheckTimer?.cancel();
    _smartTimer?.cancel();
  }

  void resetFiredStatus(String reminderId) {
    _firedReminderIds.remove(reminderId);
  }

  void scheduleNextCheck() {
    _smartTimer?.cancel();

    final now = DateTime.now();
    final activeReminders = _repo.getAll().where((r) {
      if (r.completedAt != null) return false;
      if (r.notifiedAt != null) return false;
      return true;
    }).toList();

    activeReminders.sort((a, b) => a.time.compareTo(b.time));

    // Skip past-due reminders -- zonedSchedule (Layer 1) already delivered
    // them via ScheduledNotificationReceiver. Only schedule future ones.
    final nextReminder = activeReminders
        .where((r) => r.time.isAfter(now))
        .firstOrNull;

    if (nextReminder == null) return;

    final waitDuration = nextReminder.time.difference(now);
    mDebugPrint(
      '[SmartTimer] Next check in $waitDuration for: ${nextReminder.title}',
    );

    _smartTimer = Timer(waitDuration, () {
      if (!_firedReminderIds.contains(nextReminder.id)) {
        _fireImmediate(nextReminder);
      }
      scheduleNextCheck();
    });
  }

  Future<void> _fireImmediate(ReminderEntity reminder) async {
    mDebugPrint('[SmartTimer] Firing now: ${reminder.title}');
    _firedReminderIds.add(reminder.id);
    final id = reminder.notificationId ?? reminder.id.hashCode & 0x7FFFFFFF;
    // Order matters: we stamp `notifiedAt` before `showNow()` so a fast Complete
    // action can't be overwritten by a late `markNotified()` save.
    await _repo.markNotified(reminder.id);
    await _notifications.showNow(
      id: id,
      title: 'Reminder',
      body: reminder.title,
      payload: reminder.id,
    );
  }
}
