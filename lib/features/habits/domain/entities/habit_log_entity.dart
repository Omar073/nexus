/// Domain model for a habit completion on one day.
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
