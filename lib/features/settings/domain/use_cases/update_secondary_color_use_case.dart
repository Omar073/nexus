import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

class UpdateSecondaryColorUseCase {
  UpdateSecondaryColorUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<void> call(String brightness, int color) =>
      _repo.saveSecondaryColor(brightness, color);
}
