abstract class ReminderNotifications {
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  });

  Future<void> cancel(int id);
}

