import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

class ResetColorsUseCase {
  ResetColorsUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<void> call() => _repo.resetColorsToDefaults();
}
