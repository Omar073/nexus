import 'package:flutter/material.dart';
import 'package:nexus/core/extensions/l10n_x.dart';
import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/theme_customization/views/theme_customization_screen.dart';
import 'package:provider/provider.dart';

/// Theme mode selection section
class ThemeSection extends StatelessWidget {
  const ThemeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<SettingsController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.theme, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight)),
            ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
          ],
          selected: {controller.themeMode},
          onSelectionChanged: (value) {
            final mode = value.first;
            controller.setThemeMode(mode);
          },
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Customize Appearance'),
          subtitle: const Text('Colors and navigation bar style'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Capture the controller before pushing to root navigator
            final settingsController = context.read<SettingsController>();
            // Use rootNavigator to push above the shell's bottom nav bar
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
