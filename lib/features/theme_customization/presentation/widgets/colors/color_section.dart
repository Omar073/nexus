import 'package:flutter/material.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/settings/data/models/custom_colors_store.dart';
import 'package:nexus/features/theme_customization/presentation/widgets/colors/color_option_grid.dart';
import 'package:nexus/features/theme_customization/presentation/widgets/nav_bar_styles/nav_bar_style_section.dart';
import 'package:nexus/features/theme_customization/presentation/widgets/presets/preset_list_section.dart';
import 'package:nexus/features/theme_customization/presentation/widgets/preview/theme_preview_card.dart';
import 'package:provider/provider.dart';

/// Color customization section for a specific brightness (light/dark).
class ColorSection extends StatelessWidget {
  const ColorSection({
    super.key,
    required this.brightness,
    required this.currentPrimary,
    required this.currentSecondary,
    required this.defaultPrimary,
    required this.defaultSecondary,
  });

  final Brightness brightness;
  final Color? currentPrimary;
  final Color? currentSecondary;
  final Color defaultPrimary;
  final Color defaultSecondary;

  @override
  Widget build(BuildContext context) {
    final isLight = brightness == Brightness.light;
    final textColor = isLight ? Colors.black87 : Colors.white;
    final bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF000000);

    return Container(
      color: bgColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Preview Card
          ThemePreviewCard(
            primary: currentPrimary ?? defaultPrimary,
            secondary: currentSecondary ?? defaultSecondary,
            isLight: isLight,
          ),
          const SizedBox(height: 24),

          // Saved Presets
          PresetListSection(isLight: isLight),

          // Primary Color Section
          Text(
            'Primary Color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Used for buttons, highlights, and key elements',
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          ColorOptionGrid(
            options: CustomColorsStore.primaryOptions,
            selectedColor: currentPrimary ?? defaultPrimary,
            defaultColor: defaultPrimary,
            onColorSelected: (color) {
              context.read<SettingsController>().updatePrimaryColor(
                brightness,
                color,
              );
            },
          ),
          const SizedBox(height: 24),

          // Secondary Color Section
          Text(
            'Secondary Color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Used for accents and secondary actions',
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          ColorOptionGrid(
            options: CustomColorsStore.secondaryOptions,
            selectedColor: currentSecondary ?? defaultSecondary,
            defaultColor: defaultSecondary,
            onColorSelected: (color) {
              context.read<SettingsController>().updateSecondaryColor(
                brightness,
                color,
              );
            },
          ),
          const SizedBox(height: 32),
          NavBarStyleSection(isLight: isLight),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
