import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nexus/core/services/notifications/reminder_notifications.dart';
import 'package:nexus/features/reminders/models/reminder.dart';
import 'package:nexus/features/reminders/models/reminder_repository.dart';

/// Service responsible for managing the in-app timer for reminders.
/// It supports multiple strategies (Smart Timer vs Polling).
class ReminderTimerService {
  ReminderTimerService({
    required ReminderRepository repo,
    required ReminderNotifications notifications,
  }) : _repo = repo,
       _notifications = notifications;

  final ReminderRepository _repo;
  final ReminderNotifications _notifications;

  Timer? _reminderCheckTimer;
  Timer? _smartTimer; // [NEW] Smart Timer
  final Set<String> _firedReminderIds = {};

  /// [STRATEGY DECISION]
  /// We currently use Strategy 2 (Smart Timer) for best precision and efficiency.
  ///
  /// Strategy 1: Periodic Polling (Commented out below)
  /// - Logic: Check every 30s. Trigger if due now OR in the next 30s.
  /// - Pros: Robust against edge cases.
  /// - Cons: "Bursty" CPU usage, notifications can be up to 30s early.
  ///
  /// Strategy 2: Smart Targeted Timer (Active)
  /// - Logic: Find next reminder -> Sleep exactly delta_time -> Fire -> Repeat.
  /// - Pros: 0% CPU usage while waiting, 100% time precision (active on exact second).
  /// - Cons: Requires careful state management (must reset on every CRUD op).
  ///
  /// Strategy 3: Live Stream (Tick-based) - (Not Implemented)
  /// - Logic: Subscribe to a Stream that ticks every 1 second.
  /// - Pros: Simple to reason about ("check every second"), Exact precision.
  /// - Cons: Wakes CPU 60 times/min (heavier than needed).
  ///
  /// TODO: Choose a final technique after long-term testing.
  /// Currently validating Strategy 2.

  /// Starts the active timer strategy.
  void start() {
    scheduleNextCheck();
    // _startReminderCheckTimer(); // [OLD POLLING]
  }

  /// Stops all timers.
  void dispose() {
    _reminderCheckTimer?.cancel();
    _smartTimer?.cancel();
  }

  /// Reset the fired status for a specific reminder (e.g. when snoozed or time changed).
  void resetFiredStatus(String reminderId) {
    _firedReminderIds.remove(reminderId);
  }

  // ===========================================================================
  // STRATEGY 2: SMART TIMER (ACTIVE)
  // ===========================================================================

  /// [NEW] Smart Timer Logic
  /// Finds the *next* upcoming reminder and sleeps until exactly that time.
  void scheduleNextCheck() {
    _smartTimer?.cancel();

    final now = DateTime.now();
    // 1. Get all incomplete, future reminders
    final activeReminders = _repo.getAll().where((r) {
      if (r.completedAt != null) return false;
      return true;
    }).toList();

    activeReminders.sort((a, b) => a.time.compareTo(b.time));

    // 2. Find the next one
    Reminder? nextReminder;
    for (final reminder in activeReminders) {
      // If it's in the past...
      if (reminder.time.isBefore(now)) {
        // If it was due very recently (e.g. within last 60 seconds), fire it.
        // Otherwise, assume it's an old ignored reminder and don't spam.
        final diff = now.difference(reminder.time);
        if (diff.inSeconds < 50) {
          if (!_firedReminderIds.contains(reminder.id)) {
            _fireImmediate(reminder);
          }
        }
        continue;
      }
      // Found the first future reminder
      nextReminder = reminder;
      break;
    }

    if (nextReminder == null) return;

    // 3. Schedule timer
    final waitDuration = nextReminder.time.difference(now);
    debugPrint(
      '[SmartTimer] Next check in $waitDuration for: ${nextReminder.title}',
    );

    _smartTimer = Timer(waitDuration, () {
      _fireImmediate(nextReminder!);
      scheduleNextCheck(); // Recursively schedule the next one
    });
  }

  Future<void> _fireImmediate(Reminder reminder) async {
    debugPrint('[SmartTimer] Firing now: ${reminder.title}');
    _firedReminderIds.add(reminder.id);
    await _notifications.showNow(
      id: reminder.notificationId,
      title: 'Reminder',
      body: reminder.title,
    );
  }

  // ===========================================================================
  // STRATEGY 1: POLLING (LEGACY / COMMENTED OUT)
  // ===========================================================================

  /// [OLD POLLING]
  /// Starts a periodic timer that checks for due reminders every 30 seconds.
  // void _startReminderCheckTimer() {
  //   _reminderCheckTimer?.cancel();
  //   _reminderCheckTimer = Timer.periodic(
  //     const Duration(seconds: 30),
  //     (_) => _checkDueReminders(),
  //   );
  //   // Also check immediately
  //   _checkDueReminders();
  // }

  /// [OLD POLLING]
  /// Checks if any reminders are due and fires immediate notifications.
  // Future<void> _checkDueReminders() async {
  //   final now = DateTime.now();
  //   final dueReminders = _repo.getAll().where((r) {
  //     if (r.completedAt != null) return false; // Already completed
  //     if (_firedReminderIds.contains(r.id)) return false; // Already fired
  //     // Due if the reminder time is in the past or within 1 minute from now
  //     return r.time.isBefore(now.add(const Duration(seconds: 30)));
  //   }).toList();
  //
  //   for (final reminder in dueReminders) {
  //     debugPrint(
  //       '[ReminderController] Firing immediate notification for: ${reminder.title}',
  //     );
  //     _firedReminderIds.add(reminder.id);
  //
  //     // Use the injected notification service
  //     await _notifications.showNow(
  //       id: reminder.notificationId,
  //       title: 'Reminder',
  //       body: reminder.title,
  //     );
  //   }
  // }
}
