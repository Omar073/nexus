import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';
import 'package:nexus/features/reminders/data/models/reminder.dart';

/// Maps [Reminder] Hive model to domain entity and back.

class ReminderMapper {
  static ReminderEntity toEntity(Reminder r) {
    return ReminderEntity(
      id: r.id,
      taskId: r.taskId ?? '',
      title: r.title,
      time: r.time,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      completedAt: r.completedAt,
      notificationId: r.notificationId,
      snoozeMinutes: r.snoozeMinutes,
      notifiedAt: r.notifiedAt,
    );
  }

  static Reminder toModel(ReminderEntity e) {
    return Reminder(
      id: e.id,
      notificationId: e.notificationId ?? 0,
      title: e.title,
      time: e.time,
      snoozeMinutes: e.snoozeMinutes,
      taskId: e.taskId.isEmpty ? null : e.taskId,
      completedAt: e.completedAt,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      notifiedAt: e.notifiedAt,
    );
  }
}
