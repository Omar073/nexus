import 'package:flutter/material.dart';
import 'package:nexus/features/settings/presentation/utils/nav_icon_mapper.dart';

import 'nav_shell_slots.dart';

/// Material 3 bottom bar for [NavBarStyle.standard] preview.
class MaterialNavBarPreview extends StatelessWidget {
  const MaterialNavBarPreview({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.primary,
    required this.backgroundColor,
    required this.inactiveColor,
    required this.selections,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Color primary;
  final Color backgroundColor;
  final Color inactiveColor;
  final Map<String, int> selections;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: backgroundColor,
      indicatorColor: primary.withValues(alpha: 0.2),
      destinations: [
        for (var i = 0; i < kNavShellPageIds.length; i++)
          NavigationDestination(
            icon: Icon(
              NavIconMapper.getIconForPage(kNavShellPageIds[i], selections),
              color: inactiveColor,
            ),
            selectedIcon: Icon(
              NavIconMapper.getIconForPage(
                kNavShellPageIds[i],
                selections,
                isSelected: true,
              ),
              color: primary,
            ),
            label: kNavShellLabels[i],
          ),
      ],
    );
  }
}
