import 'package:nexus/features/settings/domain/entities/color_preset_entity.dart';
import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

/// Stores the current colors as a named preset.

class SavePresetUseCase {
  SavePresetUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<void> call(ColorPresetEntity preset) => _repo.savePreset(preset);
}
