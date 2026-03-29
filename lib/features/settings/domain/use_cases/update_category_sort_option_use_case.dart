import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

/// Persists how categories are ordered.

class UpdateCategorySortOptionUseCase {
  UpdateCategorySortOptionUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<void> call(String optionName) =>
      _repo.saveCategorySortOption(optionName);
}
