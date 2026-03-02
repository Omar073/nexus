import 'package:flutter/material.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:nexus/features/theme_customization/presentation/widgets/nav_bar_styles/nav_bar_style_preview.dart';

/// Card widget for selecting a navigation bar style
class NavBarStyleCard extends StatelessWidget {
  const NavBarStyleCard({
    super.key,
    required this.style,
    required this.isSelected,
    required this.isLight,
    required this.onTap,
  });

  final NavBarStyle style;
  final bool isSelected;
  final bool isLight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : (isLight ? Colors.grey.shade300 : Colors.grey.shade700);
    final bgColor = isLight
        ? (isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.white)
        : (isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : Colors.grey.shade900);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            NavBarStylePreview(style: style, isLight: isLight),
            const SizedBox(height: 8),
            Text(
              style.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isLight ? Colors.black87 : Colors.white,
              ),
            ),
            Text(
              style.description,
              style: TextStyle(
                fontSize: 9,
                color: isLight ? Colors.black54 : Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
