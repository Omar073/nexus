import 'package:nexus/features/settings/domain/entities/app_settings_entity.dart';
import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

class LoadSettingsUseCase {
  LoadSettingsUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<AppSettingsEntity> call() => _repo.load();
}
