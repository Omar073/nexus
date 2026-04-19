import 'package:flutter/material.dart';
import 'package:nexus/app/theme/app_colors.dart';
import 'package:nexus/app/theme/app_theme_builder.dart';

/// Builds [ThemeData] for light/dark from settings and seeds.
class AppTheme {
  /// Resolves [ThemeMode.system] via [MediaQuery.platformBrightnessOf] so the
  /// result matches the OS appearance. Use a [context] under [MaterialApp].
  static ThemeData fromUserSettings(
    BuildContext context, {
    required ThemeMode themeMode,
    required Color? lightPrimary,
    required Color? lightSecondary,
    required Color? darkPrimary,
    required Color? darkSecondary,
    required DarkPalette darkPalette,
  }) {
    final brightness = switch (themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
    return brightness == Brightness.dark
        ? dark(
            customPrimary: darkPrimary,
            customSecondary: darkSecondary,
            palette: darkPalette,
          )
        : light(customPrimary: lightPrimary, customSecondary: lightSecondary);
  }

  /// Builds light theme
  static ThemeData light({Color? customPrimary, Color? customSecondary}) {
    // Nexus design system defaults
    const defaultPrimary = Color(0xFF1392EC); // Nexus Blue
    const defaultSecondary = Color(0xFF009688); // Teal

    final primary = customPrimary ?? defaultPrimary;
    final secondary = customSecondary ?? defaultSecondary;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: secondary,
      brightness: Brightness.light,
      // Nexus light background: #f6f7f8
      surface: const Color(0xFFF6F7F8),
    );

    return buildNexusTheme(colorScheme, primary, secondary);
  }

  /// Builds dark theme with palette selection
  static ThemeData dark({
    Color? customPrimary,
    Color? customSecondary,
    DarkPalette palette = DarkPalette.navy,
  }) {
    // Get palette-specific defaults
    final paletteColors = AppColors.getDark(palette);

    final primary = customPrimary ?? paletteColors.primary;
    final secondary = customSecondary ?? paletteColors.secondary;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: secondary,
      brightness: Brightness.dark,
      surface: paletteColors.background,
    );

    return buildNexusTheme(colorScheme, primary, secondary, palette: palette);
  }
}
