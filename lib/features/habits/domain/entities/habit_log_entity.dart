/// Domain entity for a habit log entry (pure Dart, no Hive).
class HabitLogEntity {
  const HabitLogEntity({
    required this.id,
    required this.habitId,
    required this.date,
    required this.createdAt,
    this.completed = true,
  });

  final String id;
  final String habitId;
  final DateTime date;
  final DateTime createdAt;
  final bool completed;
}
