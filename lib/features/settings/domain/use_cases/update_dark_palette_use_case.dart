import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

/// Updates dark-theme accent and surface colors.

class UpdateDarkPaletteUseCase {
  UpdateDarkPaletteUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<void> call(String darkPalette) => _repo.saveDarkPalette(darkPalette);
}
