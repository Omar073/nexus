import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:nexus/features/settings/presentation/utils/nav_icon_mapper.dart';

import 'nav_shell_slots.dart';

/// Google-style bottom bar for [NavBarStyle.google] preview.
class GoogleNavBarPreview extends StatelessWidget {
  const GoogleNavBarPreview({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
    required this.primary,
    required this.backgroundColor,
    required this.inactiveColor,
    required this.selections,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabChange;
  final Color primary;
  final Color backgroundColor;
  final Color inactiveColor;
  final Map<String, int> selections;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: GNav(
        selectedIndex: selectedIndex,
        onTabChange: onTabChange,
        gap: 4,
        activeColor: primary,
        iconSize: 24,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        tabBackgroundColor: primary.withValues(alpha: 0.15),
        color: inactiveColor,
        tabs: [
          for (var i = 0; i < kNavShellPageIds.length; i++)
            GButton(
              icon: NavIconMapper.getIconForPage(
                kNavShellPageIds[i],
                selections,
                isSelected: selectedIndex == i,
              ),
              text: kNavShellLabels[i],
            ),
        ],
      ),
    );
  }
}
