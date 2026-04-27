import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';

List<ReminderEntity> buildDisplayReminders(List<ReminderEntity> allReminders) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final displayReminders = allReminders.where((r) {
    final rDate = DateTime(r.time.year, r.time.month, r.time.day);
    if (rDate.isBefore(today) && r.completedAt == null) return true; // overdue
    if (rDate.isAtSameMomentAs(today)) return true; // today
    return false;
  }).toList();

  displayReminders.sort((a, b) => a.time.compareTo(b.time));
  return displayReminders;
}
