import 'package:flutter/material.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'nav_bar_style_preview_builders.dart';

/// Static illustration for a nav bar style thumbnail.
class NavBarStylePreview extends StatelessWidget {
  const NavBarStylePreview({
    super.key,
    required this.style,
    required this.isLight,
  });

  final NavBarStyle style;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = isLight ? Colors.grey.shade200 : Colors.grey.shade800;
    final iconColor = isLight ? Colors.grey.shade600 : Colors.grey.shade400;

    switch (style) {
      case NavBarStyle.standard:
        return buildStandardPreview(primaryColor, surfaceColor, iconColor);
      case NavBarStyle.curved:
        return buildCurvedPreview(primaryColor, surfaceColor, iconColor);
      case NavBarStyle.notch:
        return buildNotchPreview(primaryColor, surfaceColor, iconColor);
      case NavBarStyle.google:
        return buildGooglePreview(primaryColor, surfaceColor, iconColor);
      case NavBarStyle.rive:
        return buildRivePreview(primaryColor, surfaceColor, iconColor);
    }
  }
}
