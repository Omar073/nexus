import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/settings/presentation/utils/nav_icon_mapper.dart';
import 'package:provider/provider.dart';

/// Hosts the Google-style bottom navigation bar.
class GoogleNavBarWrapper extends StatelessWidget {
  const GoogleNavBarWrapper({
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

    final dashboardIcon = NavIconMapper.getIconForPage(
      'dashboard',
      selections,
      isSelected: selectedIndex == 0,
    );
    final tasksIcon = NavIconMapper.getIconForPage(
      'tasks',
      selections,
      isSelected: selectedIndex == 1,
    );
    final remindersIcon = NavIconMapper.getIconForPage(
      'reminders',
      selections,
      isSelected: selectedIndex == 2,
    );
    final notesIcon = NavIconMapper.getIconForPage(
      'notes',
      selections,
      isSelected: selectedIndex == 3,
    );
    final settingsIcon = NavIconMapper.getIconForPage(
      'settings',
      selections,
      isSelected: selectedIndex == 4,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(blurRadius: 20, color: Colors.black.withValues(alpha: 0.1)),
        ],
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 9),
          child: GNav(
            selectedIndex: selectedIndex,
            gap: 4,
            activeColor: colorScheme.onPrimary,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: colorScheme.primary,
            color: colorScheme.onSurfaceVariant,
            rippleColor: colorScheme.primary.withValues(alpha: 0.2),
            hoverColor: colorScheme.primary.withValues(alpha: 0.1),
            tabs: [
              GButton(icon: dashboardIcon, text: 'Dashboard'),
              GButton(icon: tasksIcon, text: 'Tasks'),
              GButton(icon: remindersIcon, text: 'Reminders'),
              GButton(icon: notesIcon, text: 'Notes'),
              GButton(icon: settingsIcon, text: 'Settings'),
            ],
            onTabChange: onDestinationSelected,
          ),
        ),
      ),
    );
  }
}
