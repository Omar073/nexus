import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

class UpdateTaskSortOptionUseCase {
  UpdateTaskSortOptionUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<void> call(String optionName) => _repo.saveTaskSortOption(optionName);
}
