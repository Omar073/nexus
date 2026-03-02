import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

class UpdateAutoDeleteCompletedTasksUseCase {
  UpdateAutoDeleteCompletedTasksUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<void> call(bool enabled) =>
      _repo.saveAutoDeleteCompletedTasks(enabled);
}
