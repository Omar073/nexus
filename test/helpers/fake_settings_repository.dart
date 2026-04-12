import 'package:nexus/features/settings/domain/entities/app_settings_entity.dart';
import 'package:nexus/features/settings/domain/entities/color_preset_entity.dart';
import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

/// Returns defaults; no-op writes for settings tests.
class FakeSettingsRepository implements SettingsRepositoryInterface {
  FakeSettingsRepository({AppSettingsEntity? loadResult})
    : _loadResult = loadResult ?? _defaultEntity;

  final AppSettingsEntity _loadResult;
  static const _defaultEntity = AppSettingsEntity(
    themeMode: 'dark',
    completedRetentionDays: 30,
    autoDeleteCompletedTasks: false,
    navBarStyle: 'standard',
    darkPalette: 'navy',
    taskSortOption: 'recentlyModified',
    categorySortOption: 'defaultOrder',
  );

  @override
  Future<AppSettingsEntity> load() async => _loadResult;

  @override
  Future<void> saveThemeMode(String themeMode) async {}

  @override
  Future<void> saveCompletedRetentionDays(int days) async {}

  @override
  Future<void> saveAutoDeleteCompletedTasks(bool enabled) async {}

  @override
  Future<void> saveNavBarStyle(String navBarStyle) async {}

  @override
  Future<void> saveDarkPalette(String darkPalette) async {}

  @override
  Future<void> saveTaskSortOption(String optionName) async {}

  @override
  Future<void> saveCategorySortOption(String optionName) async {}

  @override
  Future<void> savePrimaryColor(String brightness, int color) async {}

  @override
  Future<void> saveSecondaryColor(String brightness, int color) async {}

  @override
  Future<void> resetColorsToDefaults() async {}

  @override
  Future<void> savePreset(ColorPresetEntity preset) async {}

  @override
  Future<void> deletePreset(String id) async {}

  @override
  Future<void> saveNavigationIcons(Map<String, int> icons) async {}
}
