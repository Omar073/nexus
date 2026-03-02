import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

class UpdatePrimaryColorUseCase {
  UpdatePrimaryColorUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<void> call(String brightness, int color) =>
      _repo.savePrimaryColor(brightness, color);
}
