import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:nexus/core/services/notifications/reminder_notifications.dart';
import 'package:nexus/features/reminders/models/reminder.dart';
import 'package:nexus/features/reminders/models/reminder_repository.dart';
import 'package:uuid/uuid.dart';

class ReminderController extends ChangeNotifier {
  ReminderController({
    required ReminderRepository repo,
    required ReminderNotifications notifications,
  }) : _repo = repo,
       _notifications = notifications,
       _listenable = repo.listenable() {
    _listenable.addListener(_onLocalChanged);
    // Clean up completed reminders from previous days on startup
    _cleanupCompletedReminders();
    // Start the in-app timer to check for due reminders
    _startReminderCheckTimer();
  }

  /// Deletes reminders that were completed before today.
  /// Completed reminders stay visible until end of day, then get cleaned up.
  Future<void> _cleanupCompletedReminders() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final toDelete = _repo.getAll().where((r) {
      if (r.completedAt == null) return false;
      final completedDate = DateTime(
        r.completedAt!.year,
        r.completedAt!.month,
        r.completedAt!.day,
      );
      return completedDate.isBefore(today);
    }).toList();

    for (final reminder in toDelete) {
      await _repo.delete(reminder.id);
    }
  }

  final ReminderRepository _repo;
  final ReminderNotifications _notifications;
  final Listenable _listenable;
  Timer? _reminderCheckTimer;
  final Set<String> _firedReminderIds = {};

  static const _uuid = Uuid();

  void _onLocalChanged() => notifyListeners();

  /// Starts a periodic timer that checks for due reminders every 30 seconds.
  /// This ensures precise notifications while the app is running (foreground or cached).
  /// For background terminals, we rely on Workmanager (every 15m) as a safety net.
  /// TODO: Investigate Foreground Service for exact 60s background checks (requires permanent notification).
  void _startReminderCheckTimer() {
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkDueReminders(),
    );
    // Also check immediately
    _checkDueReminders();
  }

  /// Checks if any reminders are due and fires immediate notifications.
  Future<void> _checkDueReminders() async {
    final now = DateTime.now();
    final dueReminders = _repo.getAll().where((r) {
      if (r.completedAt != null) return false; // Already completed
      if (_firedReminderIds.contains(r.id)) return false; // Already fired
      // Due if the reminder time is in the past or within 1 minute from now
      return r.time.isBefore(now.add(const Duration(seconds: 30)));
    }).toList();

    for (final reminder in dueReminders) {
      debugPrint(
        '[ReminderController] Firing immediate notification for: ${reminder.title}',
      );
      _firedReminderIds.add(reminder.id);

      // Use the injected notification service
      await _notifications.showNow(
        id: reminder.notificationId,
        title: 'Reminder',
        body: reminder.title,
      );
    }
  }

  @override
  void dispose() {
    _reminderCheckTimer?.cancel();
    _listenable.removeListener(_onLocalChanged);
    super.dispose();
  }

  List<Reminder> get reminders {
    final all = _repo.getAll().toList()
      ..sort(
        (a, b) => b.updatedAt.compareTo(a.updatedAt),
      ); // Recently modified first
    return all;
  }

  List<Reminder> get upcoming {
    final now = DateTime.now();
    return reminders
        .where((r) => r.completedAt == null && r.time.isAfter(now))
        .toList();
  }

  Future<Reminder> create({
    required String title,
    required DateTime time,
    int? snoozeMinutes,
  }) async {
    final now = DateTime.now();
    final reminder = Reminder(
      id: _uuid.v4(),
      notificationId: now.microsecondsSinceEpoch.remainder(1 << 31),
      title: title.trim(),
      time: time,
      snoozeMinutes: snoozeMinutes,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.upsert(reminder);
    await _notifications.schedule(
      id: reminder.notificationId,
      title: 'Reminder',
      body: reminder.title,
      when: reminder.time,
    );
    return reminder;
  }

  Future<void> update(
    Reminder reminder, {
    String? title,
    DateTime? time,
  }) async {
    if (title != null) reminder.title = title.trim();
    if (time != null) reminder.time = time;
    reminder.updatedAt = DateTime.now();
    await reminder.save();
    await _notifications.cancel(reminder.notificationId);
    await _notifications.schedule(
      id: reminder.notificationId,
      title: 'Reminder',
      body: reminder.title,
      when: reminder.time,
    );
  }

  Future<void> delete(Reminder reminder) async {
    await _notifications.cancel(reminder.notificationId);
    await _repo.delete(reminder.id);
  }

  Future<void> complete(Reminder reminder) async {
    reminder.completedAt = DateTime.now();
    reminder.updatedAt = DateTime.now();
    await reminder.save();
    await _notifications.cancel(reminder.notificationId);
  }

  Future<void> uncomplete(Reminder reminder) async {
    reminder.completedAt = null;
    reminder.updatedAt = DateTime.now();
    await reminder.save();

    // Reschedule if the time is in the future
    if (reminder.time.isAfter(DateTime.now())) {
      await _notifications.schedule(
        id: reminder.notificationId,
        title: 'Reminder',
        body: reminder.title,
        when: reminder.time,
      );
    }
  }

  Future<void> snooze(Reminder reminder, {int minutes = 5}) async {
    final newTime = DateTime.now().add(Duration(minutes: minutes));
    reminder.time = newTime;
    reminder.updatedAt = DateTime.now();
    await reminder.save();
    await _notifications.cancel(reminder.notificationId);
    await _notifications.schedule(
      id: reminder.notificationId,
      title: 'Reminder (Snoozed)',
      body: reminder.title,
      when: reminder.time,
    );
  }
}
