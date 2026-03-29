import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

/// Toggles auto-removal of old completed tasks.

class UpdateAutoDeleteCompletedTasksUseCase {
  UpdateAutoDeleteCompletedTasksUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<void> call(bool enabled) =>
      _repo.saveAutoDeleteCompletedTasks(enabled);
}
