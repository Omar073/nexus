import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

class UpdateNavBarStyleUseCase {
  UpdateNavBarStyleUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<void> call(String navBarStyle) => _repo.saveNavBarStyle(navBarStyle);
}
