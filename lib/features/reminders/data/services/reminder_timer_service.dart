import 'dart:async';

import 'package:flutter/foundation.dart';
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
      return true;
    }).toList();

    activeReminders.sort((a, b) => a.time.compareTo(b.time));

    ReminderEntity? nextReminder;
    for (final reminder in activeReminders) {
      if (reminder.time.isBefore(now)) {
        final diff = now.difference(reminder.time);
        if (diff.inSeconds < 50) {
          if (!_firedReminderIds.contains(reminder.id)) {
            _fireImmediate(reminder);
          }
        }
        continue;
      }
      nextReminder = reminder;
      break;
    }

    if (nextReminder == null) return;

    final waitDuration = nextReminder.time.difference(now);
    debugPrint(
      '[SmartTimer] Next check in $waitDuration for: ${nextReminder.title}',
    );

    _smartTimer = Timer(waitDuration, () {
      _fireImmediate(nextReminder!);
      scheduleNextCheck();
    });
  }

  Future<void> _fireImmediate(ReminderEntity reminder) async {
    debugPrint('[SmartTimer] Firing now: ${reminder.title}');
    _firedReminderIds.add(reminder.id);
    final id = reminder.notificationId ?? reminder.id.hashCode & 0x7FFFFFFF;
    await _notifications.showNow(
      id: id,
      title: 'Reminder',
      body: reminder.title,
    );
  }
}
