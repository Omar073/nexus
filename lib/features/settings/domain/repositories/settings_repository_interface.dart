import 'package:nexus/features/settings/domain/entities/app_settings_entity.dart';
import 'package:nexus/features/settings/domain/entities/color_preset_entity.dart';

/// Contract for persisting and loading app settings (pure Dart).
abstract class SettingsRepositoryInterface {
  Future<AppSettingsEntity> load();

  Future<void> saveThemeMode(String themeMode);
  Future<void> saveCompletedRetentionDays(int days);
  Future<void> saveAutoDeleteCompletedTasks(bool enabled);
  Future<void> saveNavBarStyle(String navBarStyle);
  Future<void> saveDarkPalette(String darkPalette);
  Future<void> saveTaskSortOption(String optionName);
  Future<void> saveCategorySortOption(String optionName);

  Future<void> savePrimaryColor(String brightness, int color);
  Future<void> saveSecondaryColor(String brightness, int color);
  Future<void> resetColorsToDefaults();
  Future<void> savePreset(ColorPresetEntity preset);
  Future<void> deletePreset(String id);
  Future<void> saveNavigationIcons(Map<String, int> icons);
}
