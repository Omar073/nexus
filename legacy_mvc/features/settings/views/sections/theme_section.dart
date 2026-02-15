import 'package:flutter/material.dart';
import 'package:nexus/app/theme/app_colors.dart';
import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/theme_customization/views/theme_customization_screen.dart';
import 'package:provider/provider.dart';

/// Theme mode selection section
class ThemeSection extends StatelessWidget {
  const ThemeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final isDark = controller.themeMode == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Theme Mode', style: Theme.of(context).textTheme.bodyMedium),
            SegmentedButton<ThemeMode>(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: WidgetStateProperty.all(EdgeInsets.zero),
              ),
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 18),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 18),
                  label: Text('Dark'),
                ),
              ],
              selected: {controller.themeMode},
              onSelectionChanged: (value) {
                final mode = value.first;
                controller.setThemeMode(mode);
              },
            ),
          ],
        ),
        if (isDark) ...[
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('True Black (AMOLED)'),
            subtitle: const Text('Use pure black background for OLED screens'),
            value: controller.darkPalette == DarkPalette.amoled,
            onChanged: (value) {
              controller.setDarkPalette(
                value ? DarkPalette.amoled : DarkPalette.navy,
              );
            },
          ),
        ],
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Customize Appearance'),
          subtitle: const Text('Colors and navigation bar style'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            final settingsController = context.read<SettingsController>();
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider.value(
                  value: settingsController,
                  child: const ThemeCustomizationScreen(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
