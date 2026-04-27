import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';
import 'package:nexus/features/reminders/presentation/state_management/reminder_controller.dart';

ReminderEntity? findReminderById(ReminderController controller, String id) {
  return controller.reminders.cast<dynamic>().firstWhere(
    (r) => r.id == id,
    orElse: () => null,
  );
}

Future<void> deleteRemindersByIds({
  required ReminderController controller,
  required Iterable<String> ids,
}) async {
  for (final id in ids) {
    final reminder = findReminderById(controller, id);
    if (reminder != null) {
      await controller.delete(reminder);
    }
  }
}

Future<void> toggleCompletedForReminders({
  required ReminderController controller,
  required Iterable<String> ids,
}) async {
  for (final id in ids) {
    final reminder = findReminderById(controller, id);
    if (reminder == null) continue;
    if (reminder.completedAt == null) {
      await controller.complete(reminder);
    } else {
      await controller.uncomplete(reminder);
    }
  }
}

Future<void> snoozeRemindersByIds({
  required ReminderController controller,
  required Iterable<String> ids,
}) async {
  for (final id in ids) {
    final reminder = findReminderById(controller, id);
    if (reminder != null) {
      await controller.snooze(reminder);
    }
  }
}
