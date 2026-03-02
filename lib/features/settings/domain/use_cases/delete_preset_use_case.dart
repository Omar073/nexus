import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

class DeletePresetUseCase {
  DeletePresetUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<void> call(String id) => _repo.deletePreset(id);
}
