import 'package:flutter/material.dart';
import 'package:nexus/app/theme/app_colors.dart';
import 'package:nexus/features/settings/domain/entities/app_settings_entity.dart';
import 'package:nexus/features/settings/domain/entities/color_preset_entity.dart';
import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';
import 'package:nexus/features/settings/domain/use_cases/delete_preset_use_case.dart';
import 'package:nexus/features/settings/domain/use_cases/load_settings_use_case.dart';
import 'package:nexus/features/settings/domain/use_cases/reset_colors_use_case.dart';
import 'package:nexus/features/settings/domain/use_cases/save_preset_use_case.dart';
import 'package:nexus/features/settings/domain/use_cases/update_auto_delete_completed_tasks_use_case.dart';
import 'package:nexus/features/settings/domain/use_cases/update_category_sort_option_use_case.dart';
import 'package:nexus/features/settings/domain/use_cases/update_dark_palette_use_case.dart';
import 'package:nexus/features/settings/domain/use_cases/update_nav_bar_style_use_case.dart';
import 'package:nexus/features/settings/domain/use_cases/update_primary_color_use_case.dart';
import 'package:nexus/features/settings/domain/use_cases/update_secondary_color_use_case.dart';
import 'package:nexus/features/settings/domain/use_cases/update_task_sort_option_use_case.dart';
import 'package:nexus/features/settings/domain/use_cases/update_nav_icons_use_case.dart';
import 'package:nexus/features/settings/domain/use_cases/update_theme_mode_use_case.dart';
import 'package:nexus/features/settings/domain/use_cases/update_completed_retention_days_use_case.dart';
import 'package:nexus/features/settings/data/models/custom_colors_store.dart';
import 'package:nexus/features/settings/data/models/color_preset.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:nexus/features/settings/presentation/logic/settings_entity_mapper.dart';
import 'package:nexus/features/tasks/domain/task_sort_option.dart';
import 'package:nexus/features/categories/domain/category_sort_option.dart';

part 'settings_controller_colors.dart';
part 'settings_controller_nav.dart';

/// In-memory [AppSettingsEntity] plus theme/nav/task preference writes.
/// Each `update*` method delegates to a small use case and notifies listeners.

class SettingsController extends ChangeNotifier {
  SettingsController(SettingsRepositoryInterface repo)
    : _loadSettings = LoadSettingsUseCase(repo),
      _updateThemeMode = UpdateThemeModeUseCase(repo),
      _updateCompletedRetentionDays = UpdateCompletedRetentionDaysUseCase(repo),
      _updateAutoDeleteCompletedTasks = UpdateAutoDeleteCompletedTasksUseCase(
        repo,
      ),
      _updateNavBarStyle = UpdateNavBarStyleUseCase(repo),
      _updateDarkPalette = UpdateDarkPaletteUseCase(repo),
      _updateTaskSortOption = UpdateTaskSortOptionUseCase(repo),
      _updateCategorySortOption = UpdateCategorySortOptionUseCase(repo),
      _updatePrimaryColor = UpdatePrimaryColorUseCase(repo),
      _updateSecondaryColor = UpdateSecondaryColorUseCase(repo),
      _resetColors = ResetColorsUseCase(repo),
      _savePreset = SavePresetUseCase(repo),
      _deletePreset = DeletePresetUseCase(repo),
      _updateNavIcons = UpdateNavIconsUseCase(repo);

  final LoadSettingsUseCase _loadSettings;
  final UpdateThemeModeUseCase _updateThemeMode;
  final UpdateCompletedRetentionDaysUseCase _updateCompletedRetentionDays;
  final UpdateAutoDeleteCompletedTasksUseCase _updateAutoDeleteCompletedTasks;
  final UpdateNavBarStyleUseCase _updateNavBarStyle;
  final UpdateDarkPaletteUseCase _updateDarkPalette;
  final UpdateTaskSortOptionUseCase _updateTaskSortOption;
  final UpdateCategorySortOptionUseCase _updateCategorySortOption;
  final UpdatePrimaryColorUseCase _updatePrimaryColor;
  final UpdateSecondaryColorUseCase _updateSecondaryColor;
  final ResetColorsUseCase _resetColors;
  final SavePresetUseCase _savePreset;
  final DeletePresetUseCase _deletePreset;
  final UpdateNavIconsUseCase _updateNavIcons;

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  int _completedRetentionDays = 30;
  int get completedRetentionDays => _completedRetentionDays;

  bool _autoDeleteCompletedTasks = false;
  bool get autoDeleteCompletedTasks => _autoDeleteCompletedTasks;

  CustomColors _lightColors = const CustomColors();
  CustomColors _darkColors = const CustomColors();

  CustomColors get lightColors => _lightColors;
  CustomColors get darkColors => _darkColors;

  CustomColors get currentColors =>
      _themeMode == ThemeMode.dark ? _darkColors : _lightColors;

  List<ColorPreset> _presets = [];
  List<ColorPreset> get presets => List.unmodifiable(_presets);

  NavBarStyle _navBarStyle = NavBarStyle.standard;
  NavBarStyle get navBarStyle => _navBarStyle;

  DarkPalette _darkPalette = DarkPalette.navy;
  DarkPalette get darkPalette => _darkPalette;

  TaskSortOption _taskSortOption = TaskSortOption.recentlyModified;
  TaskSortOption get taskSortOption => _taskSortOption;

  CategorySortOption _categorySortOption = CategorySortOption.defaultOrder;
  CategorySortOption get categorySortOption => _categorySortOption;

  Map<String, int> _navigationIcons = {};
  Map<String, int> get navigationIcons => Map.unmodifiable(_navigationIcons);

  Future<void> load() async {
    final entity = await _loadSettings.call();
    _applyEntity(entity);
    notifyListeners();
  }

  void _applyEntity(AppSettingsEntity e) {
    _themeMode = mapThemeMode(e.themeMode);
    _completedRetentionDays = e.completedRetentionDays;
    _autoDeleteCompletedTasks = e.autoDeleteCompletedTasks;
    _navBarStyle = mapNavBarStyle(e.navBarStyle);
    _darkPalette = mapDarkPalette(e.darkPalette);
    _taskSortOption = mapTaskSortOption(e.taskSortOption);
    _categorySortOption = mapCategorySortOption(e.categorySortOption);
    _lightColors = CustomColors(
      primary: e.lightPrimary != null ? Color(e.lightPrimary!) : null,
      secondary: e.lightSecondary != null ? Color(e.lightSecondary!) : null,
    );
    _darkColors = CustomColors(
      primary: e.darkPrimary != null ? Color(e.darkPrimary!) : null,
      secondary: e.darkSecondary != null ? Color(e.darkSecondary!) : null,
    );
    _presets = List<ColorPreset>.from(e.presets.map(colorPresetFromEntity));
    _navigationIcons = Map<String, int>.from(e.navigationIcons);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _updateThemeMode.call(themeModeToStorage(mode));
  }

  Future<void> setCompletedRetentionDays(int days) async {
    final clamped = days.clamp(1, 365);
    _completedRetentionDays = clamped;
    notifyListeners();
    await _updateCompletedRetentionDays.call(clamped);
  }

  Future<void> setAutoDeleteCompletedTasks(bool enabled) async {
    _autoDeleteCompletedTasks = enabled;
    notifyListeners();
    await _updateAutoDeleteCompletedTasks.call(enabled);
  }

  Future<void> setNavBarStyle(NavBarStyle style) async {
    _navBarStyle = style;
    notifyListeners();
    await _updateNavBarStyle.call(style.name);
  }

  Future<void> setDarkPalette(DarkPalette palette) async {
    _darkPalette = palette;
    notifyListeners();
    await _updateDarkPalette.call(palette.name);
  }

  Future<void> setTaskSortOption(TaskSortOption option) async {
    _taskSortOption = option;
    notifyListeners();
    await _updateTaskSortOption.call(option.name);
  }

  Future<void> setCategorySortOption(CategorySortOption option) async {
    _categorySortOption = option;
    notifyListeners();
    await _updateCategorySortOption.call(option.name);
  }

  Future<void> reloadCustomColors() async {
    await load();
  }

  void updatePrimaryColor(Brightness brightness, Color color) {
    settingsUpdatePrimaryColor(this, brightness, color);
    notifyListeners();
  }

  void updateSecondaryColor(Brightness brightness, Color color) {
    settingsUpdateSecondaryColor(this, brightness, color);
    notifyListeners();
  }

  void resetColors() {
    settingsResetColors(this);
    notifyListeners();
  }

  static const Color _defaultLightPrimary = Color(0xFF1392EC);
  static const Color _defaultLightSecondary = Color(0xFF009688);
  static const Color _defaultDarkPrimary = Color(0xFF1392EC);
  static const Color _defaultDarkSecondary = Color(0xFF80CBC4);

  Future<void> saveCurrentAsPreset(String name) async {
    await settingsSaveCurrentAsPreset(this, name);
    notifyListeners();
  }

  void applyPreset(ColorPreset preset) {
    settingsApplyPreset(this, preset);
    notifyListeners();
  }

  Future<void> deletePreset(String id) async {
    await settingsDeletePreset(this, id);
    notifyListeners();
  }

  Future<void> setNavIcon(String page, IconData icon) async {
    await settingsSetNavIcon(this, page, icon);
    notifyListeners();
  }
}
