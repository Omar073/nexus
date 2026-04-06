import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

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
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: GNav(
            selectedIndex: selectedIndex,
            gap: 4,
            activeColor: colorScheme.onPrimary,
            iconSize: 22,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: colorScheme.primary,
            color: colorScheme.onSurfaceVariant,
            rippleColor: colorScheme.primary.withValues(alpha: 0.2),
            hoverColor: colorScheme.primary.withValues(alpha: 0.1),
            tabs: const [
              GButton(icon: Icons.dashboard_outlined, text: 'Dashboard'),
              GButton(icon: Icons.checklist_outlined, text: 'Tasks'),
              GButton(icon: Icons.alarm_outlined, text: 'Reminders'),
              GButton(icon: Icons.note_outlined, text: 'Notes'),
              GButton(icon: Icons.settings_outlined, text: 'Settings'),
            ],
            onTabChange: onDestinationSelected,
          ),
        ),
      ),
    );
  }
}
