import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

class UpdateNavIconsUseCase {
  UpdateNavIconsUseCase(this._repository);

  final SettingsRepositoryInterface _repository;

  Future<void> call(Map<String, int> icons) async {
    await _repository.saveNavigationIcons(icons);
  }
}
