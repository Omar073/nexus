import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/settings/presentation/utils/nav_icon_mapper.dart';
import 'package:provider/provider.dart';

/// Hosts the curved labeled bottom navigation bar.
class CurvedNavBarWrapper extends StatelessWidget {
  static const double height = 65.0;

  const CurvedNavBarWrapper({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final selections = context.watch<SettingsController>().navigationIcons;

    return SafeArea(
      child: CurvedNavigationBar(
        index: selectedIndex,
        height: height,
        backgroundColor: Colors.transparent,
        color: isDark
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest,
        buttonBackgroundColor: colorScheme.primary,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        items: [
          CurvedNavigationBarItem(
            child: Icon(
              NavIconMapper.getIconForPage(
                'dashboard',
                selections,
                isSelected: selectedIndex == 0,
              ),
              color: selectedIndex == 0
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            label: 'Dashboard',
            labelStyle: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              NavIconMapper.getIconForPage(
                'tasks',
                selections,
                isSelected: selectedIndex == 1,
              ),
              color: selectedIndex == 1
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            label: 'Tasks',
            labelStyle: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              NavIconMapper.getIconForPage(
                'reminders',
                selections,
                isSelected: selectedIndex == 2,
              ),
              color: selectedIndex == 2
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            label: 'Reminders',
            labelStyle: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              NavIconMapper.getIconForPage(
                'notes',
                selections,
                isSelected: selectedIndex == 3,
              ),
              color: selectedIndex == 3
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            label: 'Notes',
            labelStyle: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              NavIconMapper.getIconForPage(
                'settings',
                selections,
                isSelected: selectedIndex == 4,
              ),
              color: selectedIndex == 4
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            label: 'Settings',
            labelStyle: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        onTap: onDestinationSelected,
      ),
    );
  }
}
