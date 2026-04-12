import 'package:flutter/material.dart';
import 'package:nexus/features/settings/domain/entities/app_settings_entity.dart';
import 'package:nexus/features/settings/domain/entities/color_preset_entity.dart';
import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';
import 'package:nexus/features/settings/data/models/color_preset.dart';
import 'package:nexus/features/settings/data/models/custom_colors_store.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:nexus/app/theme/app_colors.dart';
import 'package:nexus/features/settings/data/models/settings_store.dart';

/// Maps [SettingsStore] and color stores to domain settings.
class SettingsRepositoryImpl implements SettingsRepositoryInterface {
  SettingsRepositoryImpl({SettingsStore? store, CustomColorsStore? colorsStore})
    : _store = store ?? SettingsStore(),
      _colorsStore = colorsStore ?? CustomColorsStore();

  final SettingsStore _store;
  final CustomColorsStore _colorsStore;

  @override
  Future<AppSettingsEntity> load() async {
    final themeMode = await _store.loadThemeMode();
    final completedRetentionDays = await _store.loadCompletedRetentionDays();
    final autoDeleteCompletedTasks = await _store
        .loadAutoDeleteCompletedTasks();
    final navBarStyle = await _store.loadNavBarStyle();
    final darkPalette = await _store.loadDarkPalette();
    final taskSortOption = await _store.loadTaskSortOption();
    final categorySortOption = await _store.loadCategorySortOption();
    final lightColors = await _colorsStore.loadColors(Brightness.light);
    final darkColors = await _colorsStore.loadColors(Brightness.dark);
    final presets = await _colorsStore.loadPresets();
    final navigationIcons = await _store.loadNavigationIcons();

    return AppSettingsEntity(
      themeMode: _themeModeToString(themeMode),
      completedRetentionDays: completedRetentionDays,
      autoDeleteCompletedTasks: autoDeleteCompletedTasks,
      navBarStyle: navBarStyle.name,
      darkPalette: darkPalette.name,
      taskSortOption: taskSortOption ?? 'recentlyModified',
      categorySortOption: categorySortOption ?? 'defaultOrder',
      lightPrimary: lightColors.primary?.toARGB32(),
      lightSecondary: lightColors.secondary?.toARGB32(),
      darkPrimary: darkColors.primary?.toARGB32(),
      darkSecondary: darkColors.secondary?.toARGB32(),
      presets: presets.map(_presetToEntity).toList(),
      navigationIcons: navigationIcons,
    );
  }

  static String _themeModeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  static ColorPresetEntity _presetToEntity(ColorPreset p) {
    return ColorPresetEntity(
      id: p.id,
      name: p.name,
      lightPrimary: p.lightPrimary.toARGB32(),
      lightSecondary: p.lightSecondary.toARGB32(),
      darkPrimary: p.darkPrimary.toARGB32(),
      darkSecondary: p.darkSecondary.toARGB32(),
      createdAtIso: p.createdAt.toIso8601String(),
    );
  }

  @override
  Future<void> saveThemeMode(String themeMode) async {
    final mode = switch (themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };
    await _store.saveThemeMode(mode);
  }

  @override
  Future<void> saveCompletedRetentionDays(int days) async {
    await _store.saveCompletedRetentionDays(days);
  }

  @override
  Future<void> saveAutoDeleteCompletedTasks(bool enabled) async {
    await _store.saveAutoDeleteCompletedTasks(enabled);
  }

  @override
  Future<void> saveNavBarStyle(String navBarStyle) async {
    final style = switch (navBarStyle) {
      'curved' => NavBarStyle.curved,
      'notch' => NavBarStyle.notch,
      'google' => NavBarStyle.google,
      'rive' => NavBarStyle.rive,
      _ => NavBarStyle.standard,
    };
    await _store.saveNavBarStyle(style);
  }

  @override
  Future<void> saveDarkPalette(String darkPalette) async {
    final palette = darkPalette == 'amoled'
        ? DarkPalette.amoled
        : DarkPalette.navy;
    await _store.saveDarkPalette(palette);
  }

  @override
  Future<void> saveTaskSortOption(String optionName) async {
    await _store.saveTaskSortOption(optionName);
  }

  @override
  Future<void> saveCategorySortOption(String optionName) async {
    await _store.saveCategorySortOption(optionName);
  }

  @override
  Future<void> savePrimaryColor(String brightness, int color) async {
    final b = brightness == 'light' ? Brightness.light : Brightness.dark;
    await _colorsStore.savePrimaryColor(b, Color(color));
  }

  @override
  Future<void> saveSecondaryColor(String brightness, int color) async {
    final b = brightness == 'light' ? Brightness.light : Brightness.dark;
    await _colorsStore.saveSecondaryColor(b, Color(color));
  }

  @override
  Future<void> resetColorsToDefaults() async {
    await _colorsStore.resetToDefaults();
  }

  @override
  Future<void> savePreset(ColorPresetEntity preset) async {
    final p = ColorPreset(
      id: preset.id,
      name: preset.name,
      lightPrimary: Color(preset.lightPrimary),
      lightSecondary: Color(preset.lightSecondary),
      darkPrimary: Color(preset.darkPrimary),
      darkSecondary: Color(preset.darkSecondary),
      createdAt: DateTime.parse(preset.createdAtIso),
    );
    await _colorsStore.savePreset(p);
  }

  @override
  Future<void> deletePreset(String id) async {
    await _colorsStore.deletePreset(id);
  }

  @override
  Future<void> saveNavigationIcons(Map<String, int> icons) async {
    await _store.saveNavigationIcons(icons);
  }
}
