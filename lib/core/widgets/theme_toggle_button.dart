import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nexus/features/settings/controllers/settings_controller.dart';

/// A theme toggle button that switches between light and dark themes
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final themeMode = controller.themeMode;
    final isDark = themeMode == ThemeMode.dark;

    return IconButton(
      icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
      tooltip: isDark ? 'Theme: Dark' : 'Theme: Light',
      onPressed: () => _toggleTheme(controller, isDark),
    );
  }

  void _toggleTheme(SettingsController controller, bool isDark) {
    controller.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
