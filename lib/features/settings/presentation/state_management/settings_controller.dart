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
import 'package:nexus/features/settings/domain/use_cases/update_theme_mode_use_case.dart';
import 'package:nexus/features/settings/domain/use_cases/update_completed_retention_days_use_case.dart';
import 'package:nexus/features/settings/data/models/custom_colors_store.dart';
import 'package:nexus/features/settings/data/models/color_preset.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:nexus/features/tasks/domain/task_sort_option.dart';
import 'package:nexus/features/categories/domain/category_sort_option.dart';

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
      _deletePreset = DeletePresetUseCase(repo);

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

  Future<void> load() async {
    final entity = await _loadSettings.call();
    _applyEntity(entity);
    notifyListeners();
  }

  void _applyEntity(AppSettingsEntity e) {
    _themeMode = e.themeMode == 'light' ? ThemeMode.light : ThemeMode.dark;
    _completedRetentionDays = e.completedRetentionDays;
    _autoDeleteCompletedTasks = e.autoDeleteCompletedTasks;
    _navBarStyle = NavBarStyle.values.firstWhere(
      (s) => s.name == e.navBarStyle,
      orElse: () => NavBarStyle.standard,
    );
    _darkPalette = e.darkPalette == 'amoled'
        ? DarkPalette.amoled
        : DarkPalette.navy;
    _taskSortOption = TaskSortOption.values.firstWhere(
      (o) => o.name == e.taskSortOption,
      orElse: () => TaskSortOption.recentlyModified,
    );
    _categorySortOption = CategorySortOption.values.firstWhere(
      (o) => o.name == e.categorySortOption,
      orElse: () => CategorySortOption.defaultOrder,
    );
    _lightColors = CustomColors(
      primary: e.lightPrimary != null ? Color(e.lightPrimary!) : null,
      secondary: e.lightSecondary != null ? Color(e.lightSecondary!) : null,
    );
    _darkColors = CustomColors(
      primary: e.darkPrimary != null ? Color(e.darkPrimary!) : null,
      secondary: e.darkSecondary != null ? Color(e.darkSecondary!) : null,
    );
    _presets = List<ColorPreset>.from(e.presets.map(_presetFromEntity));
  }

  static ColorPreset _presetFromEntity(ColorPresetEntity e) {
    return ColorPreset(
      id: e.id,
      name: e.name,
      lightPrimary: Color(e.lightPrimary),
      lightSecondary: Color(e.lightSecondary),
      darkPrimary: Color(e.darkPrimary),
      darkSecondary: Color(e.darkSecondary),
      createdAt: DateTime.parse(e.createdAtIso),
    );
  }

  static String _themeModeToString(ThemeMode mode) =>
      mode == ThemeMode.light ? 'light' : 'dark';

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _updateThemeMode.call(_themeModeToString(mode));
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
    if (brightness == Brightness.light) {
      _lightColors = CustomColors(
        primary: color,
        secondary: _lightColors.secondary,
      );
    } else {
      _darkColors = CustomColors(
        primary: color,
        secondary: _darkColors.secondary,
      );
    }
    notifyListeners();
    _updatePrimaryColor.call(
      brightness == Brightness.light ? 'light' : 'dark',
      color.toARGB32(),
    );
  }

  void updateSecondaryColor(Brightness brightness, Color color) {
    if (brightness == Brightness.light) {
      _lightColors = CustomColors(
        primary: _lightColors.primary,
        secondary: color,
      );
    } else {
      _darkColors = CustomColors(
        primary: _darkColors.primary,
        secondary: color,
      );
    }
    notifyListeners();
    _updateSecondaryColor.call(
      brightness == Brightness.light ? 'light' : 'dark',
      color.toARGB32(),
    );
  }

  void resetColors() {
    _lightColors = const CustomColors();
    _darkColors = const CustomColors();
    notifyListeners();
    _resetColors.call();
  }

  static const Color _defaultLightPrimary = Color(0xFF1392EC);
  static const Color _defaultLightSecondary = Color(0xFF009688);
  static const Color _defaultDarkPrimary = Color(0xFF1392EC);
  static const Color _defaultDarkSecondary = Color(0xFF80CBC4);

  Future<void> saveCurrentAsPreset(String name) async {
    final preset = ColorPresetEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      lightPrimary: (_lightColors.primary ?? _defaultLightPrimary).toARGB32(),
      lightSecondary: (_lightColors.secondary ?? _defaultLightSecondary)
          .toARGB32(),
      darkPrimary: (_darkColors.primary ?? _defaultDarkPrimary).toARGB32(),
      darkSecondary: (_darkColors.secondary ?? _defaultDarkSecondary)
          .toARGB32(),
      createdAtIso: DateTime.now().toIso8601String(),
    );
    await _savePreset.call(preset);
    _presets.add(_presetFromEntity(preset));
    notifyListeners();
  }

  void applyPreset(ColorPreset preset) {
    _lightColors = CustomColors(
      primary: preset.lightPrimary,
      secondary: preset.lightSecondary,
    );
    _darkColors = CustomColors(
      primary: preset.darkPrimary,
      secondary: preset.darkSecondary,
    );
    notifyListeners();
    _updatePrimaryColor.call('light', preset.lightPrimary.toARGB32());
    _updateSecondaryColor.call('light', preset.lightSecondary.toARGB32());
    _updatePrimaryColor.call('dark', preset.darkPrimary.toARGB32());
    _updateSecondaryColor.call('dark', preset.darkSecondary.toARGB32());
  }

  Future<void> deletePreset(String id) async {
    await _deletePreset.call(id);
    _presets.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
