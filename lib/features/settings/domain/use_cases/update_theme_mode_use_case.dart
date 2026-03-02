import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

class UpdateThemeModeUseCase {
  UpdateThemeModeUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<void> call(String themeMode) => _repo.saveThemeMode(themeMode);
}
