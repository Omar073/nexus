import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

/// Restores default light/dark palette values.

class ResetColorsUseCase {
  ResetColorsUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<void> call() => _repo.resetColorsToDefaults();
}
