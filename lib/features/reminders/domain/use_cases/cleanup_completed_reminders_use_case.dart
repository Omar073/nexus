import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';

/// Deletes reminders that were completed before today.
class CleanupCompletedRemindersUseCase {
  CleanupCompletedRemindersUseCase(this._repo);

  final ReminderRepositoryInterface _repo;

  Future<void> call() async {
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

    for (final r in toDelete) {
      await _repo.delete(r.id);
    }
  }
}
