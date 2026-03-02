import 'package:flutter/material.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/theme_customization/presentation/widgets/nav_bar_styles/nav_bar_style_card.dart';
import 'package:nexus/features/theme_customization/presentation/widgets/nav_bar_styles/nav_bar_preview.dart';
import 'package:provider/provider.dart';

/// Widget section to select navigation bar style with visual previews.
class NavBarStyleSection extends StatelessWidget {
  const NavBarStyleSection({super.key, required this.isLight});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final textColor = isLight ? Colors.black87 : Colors.white;
    final selectedStyle = settings.navBarStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Navigation Bar Style',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how the bottom navigation bar looks',
          style: TextStyle(
            fontSize: 12,
            color: textColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: NavBarStyle.values.map((style) {
            final isSelected = selectedStyle == style;
            return NavBarStyleCard(
              style: style,
              isSelected: isSelected,
              isLight: isLight,
              onTap: () => settings.setNavBarStyle(style),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Preview',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        NavBarPreview(style: selectedStyle, isLight: isLight),
      ],
    );
  }
}
