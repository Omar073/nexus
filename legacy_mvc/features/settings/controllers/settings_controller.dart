import 'package:flutter/material.dart';
import 'package:nexus/app/theme/app_colors.dart';
import 'package:nexus/features/settings/models/settings_store.dart';
import 'package:nexus/features/settings/models/custom_colors_store.dart';
import 'package:nexus/features/settings/models/color_preset.dart';
import 'package:nexus/features/settings/models/nav_bar_style.dart';
import 'package:nexus/features/tasks/models/task_sort_option.dart';
import 'package:nexus/features/tasks/models/category_sort_option.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({SettingsStore? store, CustomColorsStore? colorsStore})
    : _store = store ?? SettingsStore(),
      _colorsStore = colorsStore ?? CustomColorsStore();

  final SettingsStore _store;
  final CustomColorsStore _colorsStore;

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  int _completedRetentionDays = 30;
  int get completedRetentionDays => _completedRetentionDays;

  bool _autoDeleteCompletedTasks = false;
  bool get autoDeleteCompletedTasks => _autoDeleteCompletedTasks;

  // Custom colors
  CustomColors _lightColors = const CustomColors();
  CustomColors _darkColors = const CustomColors();

  CustomColors get lightColors => _lightColors;
  CustomColors get darkColors => _darkColors;

  /// Get custom colors for the current theme mode
  CustomColors get currentColors =>
      _themeMode == ThemeMode.dark ? _darkColors : _lightColors;

  // Color presets
  List<ColorPreset> _presets = [];
  List<ColorPreset> get presets => List.unmodifiable(_presets);

  // Navigation bar style
  NavBarStyle _navBarStyle = NavBarStyle.standard;
  NavBarStyle get navBarStyle => _navBarStyle;

  // Dark theme palette (Navy or AMOLED)
  DarkPalette _darkPalette = DarkPalette.navy;
  DarkPalette get darkPalette => _darkPalette;

  // Task sort option
  TaskSortOption _taskSortOption = TaskSortOption.recentlyModified;
  TaskSortOption get taskSortOption => _taskSortOption;

  Future<void> load() async {
    _themeMode = await _store.loadThemeMode();
    _completedRetentionDays = await _store.loadCompletedRetentionDays();
    _autoDeleteCompletedTasks = await _store.loadAutoDeleteCompletedTasks();

    // Load custom colors
    _lightColors = await _colorsStore.loadColors(Brightness.light);
    _darkColors = await _colorsStore.loadColors(Brightness.dark);

    // Load presets
    _presets = await _colorsStore.loadPresets();

    // Load nav bar style
    _navBarStyle = await _store.loadNavBarStyle();

    // Load dark palette preference
    _darkPalette = await _store.loadDarkPalette();

    // Load task sort option
    final sortName = await _store.loadTaskSortOption();
    _taskSortOption = TaskSortOption.values.firstWhere(
      (e) => e.name == sortName,
      orElse: () => TaskSortOption.recentlyModified,
    );

    // Load category sort option
    final catSortName = await _store.loadCategorySortOption();
    _categorySortOption = CategorySortOption.values.firstWhere(
      (e) => e.name == catSortName,
      orElse: () => CategorySortOption.defaultOrder,
    );

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _store.saveThemeMode(mode);
  }

  Future<void> setCompletedRetentionDays(int days) async {
    final clamped = days.clamp(1, 365);
    _completedRetentionDays = clamped;
    notifyListeners();
    await _store.saveCompletedRetentionDays(clamped);
  }

  Future<void> setAutoDeleteCompletedTasks(bool enabled) async {
    _autoDeleteCompletedTasks = enabled;
    notifyListeners();
    await _store.saveAutoDeleteCompletedTasks(enabled);
  }

  /// Set navigation bar style
  Future<void> setNavBarStyle(NavBarStyle style) async {
    _navBarStyle = style;
    notifyListeners();
    await _store.saveNavBarStyle(style);
  }

  /// Set dark theme palette (Navy or AMOLED)
  Future<void> setDarkPalette(DarkPalette palette) async {
    _darkPalette = palette;
    notifyListeners();
    await _store.saveDarkPalette(palette);
  }

  /// Set task sort option
  Future<void> setTaskSortOption(TaskSortOption option) async {
    _taskSortOption = option;
    notifyListeners();
    await _store.saveTaskSortOption(option.name);
  }

  // Category sort option
  CategorySortOption _categorySortOption = CategorySortOption.defaultOrder;
  CategorySortOption get categorySortOption => _categorySortOption;

  /// Set category sort option
  Future<void> setCategorySortOption(CategorySortOption option) async {
    _categorySortOption = option;
    notifyListeners();
    await _store.saveCategorySortOption(option.name);
  }

  /// Reload custom colors (called after customization screen saves)
  Future<void> reloadCustomColors() async {
    _lightColors = await _colorsStore.loadColors(Brightness.light);
    _darkColors = await _colorsStore.loadColors(Brightness.dark);
    notifyListeners();
  }

  /// Optimistically update primary color and save to storage
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
    _colorsStore.savePrimaryColor(brightness, color);
  }

  /// Optimistically update secondary color and save to storage
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
    _colorsStore.saveSecondaryColor(brightness, color);
  }

  /// Reset colors optimistically
  void resetColors() {
    _lightColors = const CustomColors();
    _darkColors = const CustomColors();
    notifyListeners();
    _colorsStore.resetToDefaults();
  }

  // ============================================================================
  // Preset Management
  // ============================================================================

  /// Default colors for presets - Updated to Nexus design system
  static const Color _defaultLightPrimary = Color(0xFF1392EC);
  static const Color _defaultLightSecondary = Color(0xFF009688);
  static const Color _defaultDarkPrimary = Color(0xFF1392EC);
  static const Color _defaultDarkSecondary = Color(0xFF80CBC4);

  /// Save current colors as a new preset
  Future<void> saveCurrentAsPreset(String name) async {
    final preset = ColorPreset.fromCurrentColors(
      name: name,
      lightPrimary: _lightColors.primary ?? _defaultLightPrimary,
      lightSecondary: _lightColors.secondary ?? _defaultLightSecondary,
      darkPrimary: _darkColors.primary ?? _defaultDarkPrimary,
      darkSecondary: _darkColors.secondary ?? _defaultDarkSecondary,
    );
    _presets.add(preset);
    notifyListeners();
    await _colorsStore.savePreset(preset);
  }

  /// Apply a preset's colors
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
    // Save to storage
    _colorsStore.savePrimaryColor(Brightness.light, preset.lightPrimary);
    _colorsStore.saveSecondaryColor(Brightness.light, preset.lightSecondary);
    _colorsStore.savePrimaryColor(Brightness.dark, preset.darkPrimary);
    _colorsStore.saveSecondaryColor(Brightness.dark, preset.darkSecondary);
  }

  /// Delete a preset
  Future<void> deletePreset(String id) async {
    _presets.removeWhere((p) => p.id == id);
    notifyListeners();
    await _colorsStore.deletePreset(id);
  }
}
