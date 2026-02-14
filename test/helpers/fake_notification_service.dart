import 'package:nexus/core/services/notifications/reminder_notifications.dart';

/// Reusable fake for [ReminderNotifications].
///
/// Records every schedule, cancel, and showNow call so tests can
/// assert notification side effects.
class FakeNotificationService implements ReminderNotifications {
  final scheduled = <int, DateTime>{};
  final canceled = <int>[];
  final shownNow = <int, String>{};

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    scheduled[id] = when;
  }

  @override
  Future<void> cancel(int id) async {
    canceled.add(id);
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    shownNow[id] = body;
  }

  void reset() {
    scheduled.clear();
    canceled.clear();
    shownNow.clear();
  }
}
