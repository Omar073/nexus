import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

/// Removes a saved color preset from storage.

class DeletePresetUseCase {
  DeletePresetUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<void> call(String id) => _repo.deletePreset(id);
}
