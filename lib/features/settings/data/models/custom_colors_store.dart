import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus/features/settings/data/models/color_preset.dart';

/// Loads and saves custom colors per brightness.
class CustomColorsStore {
  static const _keyLightPrimary = 'custom_colors.light_primary';
  static const _keyLightSecondary = 'custom_colors.light_secondary';
  static const _keyDarkPrimary = 'custom_colors.dark_primary';
  static const _keyDarkSecondary = 'custom_colors.dark_secondary';
  static const _keyPresets = 'custom_colors.presets';

  /// Recommended primary color options
  static const List<ColorOption> primaryOptions = [
    ColorOption('Indigo', Color(0xFF3F51B5)),
    ColorOption('Blue', Color(0xFF2196F3)),
    ColorOption('Purple', Color(0xFF9C27B0)),
    ColorOption('Deep Purple', Color(0xFF673AB7)),
    ColorOption('Teal', Color(0xFF009688)),
    ColorOption('Green', Color(0xFF4CAF50)),
    ColorOption('Orange', Color(0xFFFF9800)),
    ColorOption('Red', Color(0xFFF44336)),
    ColorOption('Pink', Color(0xFFE91E63)),
    ColorOption('Cyan', Color(0xFF00BCD4)),
  ];

  /// Recommended secondary color options
  static const List<ColorOption> secondaryOptions = [
    ColorOption('Teal', Color(0xFF009688)),
    ColorOption('Amber', Color(0xFFFFC107)),
    ColorOption('Cyan', Color(0xFF00BCD4)),
    ColorOption('Lime', Color(0xFFCDDC39)),
    ColorOption('Deep Orange', Color(0xFFFF5722)),
    ColorOption('Light Blue', Color(0xFF03A9F4)),
    ColorOption('Green', Color(0xFF4CAF50)),
    ColorOption('Purple', Color(0xFF9C27B0)),
  ];

  /// Load custom colors for a theme mode
  Future<CustomColors> loadColors(Brightness brightness) async {
    final prefs = await SharedPreferences.getInstance();

    if (brightness == Brightness.light) {
      return CustomColors(
        primary: _loadColor(prefs, _keyLightPrimary),
        secondary: _loadColor(prefs, _keyLightSecondary),
      );
    } else {
      return CustomColors(
        primary: _loadColor(prefs, _keyDarkPrimary),
        secondary: _loadColor(prefs, _keyDarkSecondary),
      );
    }
  }

  /// Save custom primary color
  Future<void> savePrimaryColor(Brightness brightness, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final key = brightness == Brightness.light
        ? _keyLightPrimary
        : _keyDarkPrimary;
    await prefs.setInt(key, color.toARGB32());
  }

  /// Save custom secondary color
  Future<void> saveSecondaryColor(Brightness brightness, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final key = brightness == Brightness.light
        ? _keyLightSecondary
        : _keyDarkSecondary;
    await prefs.setInt(key, color.toARGB32());
  }

  /// Reset all custom colors to defaults
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLightPrimary);
    await prefs.remove(_keyLightSecondary);
    await prefs.remove(_keyDarkPrimary);
    await prefs.remove(_keyDarkSecondary);
  }

  /// Check if any custom colors are set
  Future<bool> hasCustomColors() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyLightPrimary) ||
        prefs.containsKey(_keyLightSecondary) ||
        prefs.containsKey(_keyDarkPrimary) ||
        prefs.containsKey(_keyDarkSecondary);
  }

  Color? _loadColor(SharedPreferences prefs, String key) {
    final value = prefs.getInt(key);
    return value != null ? Color(value) : null;
  }

  // ============================================================================
  // Preset Management
  // ============================================================================

  /// Load all saved presets
  Future<List<ColorPreset>> loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyPresets);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      return ColorPreset.decodeList(jsonString);
    } catch (e) {
      return [];
    }
  }

  /// Save a new preset
  Future<void> savePreset(ColorPreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    final presets = await loadPresets();
    presets.add(preset);
    await prefs.setString(_keyPresets, ColorPreset.encodeList(presets));
  }

  /// Delete a preset by ID
  Future<void> deletePreset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final presets = await loadPresets();
    presets.removeWhere((p) => p.id == id);
    await prefs.setString(_keyPresets, ColorPreset.encodeList(presets));
  }
}

/// Serializable light/dark color set for presets.
class CustomColors {
  final Color? primary;
  final Color? secondary;

  const CustomColors({this.primary, this.secondary});

  bool get hasCustomPrimary => primary != null;
  bool get hasCustomSecondary => secondary != null;
  bool get hasAnyCustom => hasCustomPrimary || hasCustomSecondary;
}

/// One selectable swatch entry inside custom color storage.
class ColorOption {
  final String name;
  final Color color;

  const ColorOption(this.name, this.color);
}
