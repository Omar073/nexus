import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:nexus/core/services/notifications/reminder_notifications.dart';
import 'package:nexus/features/reminders/models/reminder.dart';
import 'package:nexus/features/reminders/models/reminder_repository.dart';
import 'package:nexus/features/reminders/services/reminder_timer_service.dart';
import 'package:uuid/uuid.dart';

class ReminderController extends ChangeNotifier {
  ReminderController({
    required ReminderRepository repo,
    required ReminderNotifications notifications,
  }) : _repo = repo,
       _notifications = notifications,
       _timerService = ReminderTimerService(
         repo: repo,
         notifications: notifications,
       ),
       _listenable = repo.listenable() {
    _listenable.addListener(_onLocalChanged);
    // Clean up completed reminders from previous days on startup
    _cleanupCompletedReminders();
    // Start the Timer Service
    _timerService.start();
  }

  final ReminderRepository _repo;
  final ReminderNotifications _notifications;
  final ReminderTimerService _timerService;
  final Listenable _listenable;

  static const _uuid = Uuid();

  void _onLocalChanged() => notifyListeners();

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

  @override
  void dispose() {
    _timerService.dispose();
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
    _timerService.scheduleNextCheck(); // Hook: Re-calc smart timer
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
    if (time != null) {
      // Hook: Reset fired status if time changed
      _timerService.resetFiredStatus(reminder.id);
    }
    _timerService.scheduleNextCheck(); // Hook: Re-calc smart timer
  }

  Future<void> delete(Reminder reminder) async {
    await _notifications.cancel(reminder.notificationId);
    await _repo.delete(reminder.id);
    _timerService.scheduleNextCheck(); // Hook: Re-calc smart timer
  }

  Future<void> complete(Reminder reminder) async {
    reminder.completedAt = DateTime.now();
    reminder.updatedAt = DateTime.now();
    await reminder.save();
    await _notifications.cancel(reminder.notificationId);
    _timerService.scheduleNextCheck(); // Hook: Re-calc smart timer
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
    _timerService.resetFiredStatus(reminder.id); // Hook: Allow firing again
    _timerService.scheduleNextCheck(); // Hook: Re-calc smart timer
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
    _timerService.resetFiredStatus(reminder.id); // Hook: Allow firing again
    _timerService.scheduleNextCheck(); // Hook: Re-calc smart timer
  }
}
