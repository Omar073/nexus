import 'package:flutter/material.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/theme_customization/presentation/widgets/presets/save_preset_dialog.dart';

int initialThemeTabIndex(SettingsController settings) =>
    settings.themeMode == ThemeMode.dark ? 1 : 0;

ThemeData buildThemeCustomizationPreviewTheme({
  required SettingsController settings,
  required bool isLight,
}) {
  final previewPrimary = isLight
      ? (settings.lightColors.primary ?? const Color(0xFF3F51B5))
      : (settings.darkColors.primary ?? const Color(0xFF9FA8DA));

  if (isLight) {
    return ThemeData.light().copyWith(
      colorScheme: ColorScheme.light(
        primary: previewPrimary,
        surface: Colors.white,
        onSurface: Colors.black87,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: previewPrimary,
        unselectedLabelColor: Colors.black54,
        indicatorColor: previewPrimary,
      ),
    );
  }

  return ThemeData.dark().copyWith(
    colorScheme: ColorScheme.dark(
      primary: previewPrimary,
      surface: const Color(0xFF000000),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF000000),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: previewPrimary,
      unselectedLabelColor: Colors.white54,
      indicatorColor: previewPrimary,
    ),
  );
}

Future<void> saveThemePresetWithFeedback({
  required BuildContext context,
  required SettingsController settings,
}) async {
  final name = await SavePresetDialog.show(context);
  if (name == null || !context.mounted) return;
  await settings.saveCurrentAsPreset(name);
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Saved preset "$name"')));
}

void resetThemeColorsWithFeedback({
  required BuildContext context,
  required SettingsController settings,
}) {
  settings.resetColors();
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Colors reset to defaults')));
}
