abstract class ReminderNotifications {
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  });

  Future<void> cancel(int id);

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool silent = false,
  });
}
