/// Domain reminder with schedule and completion state.
class ReminderEntity {
  const ReminderEntity({
    required this.id,
    required this.taskId,
    required this.title,
    required this.time,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.notificationId,
    this.snoozeMinutes,
    this.notifiedAt,
  });

  final String id;
  final String taskId;
  final String title;
  final DateTime time;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final int? notificationId;
  final int? snoozeMinutes;
  final DateTime? notifiedAt;
}
