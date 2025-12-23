import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:nexus/core/extensions/l10n_x.dart';

/// Google-style navigation bar wrapper using google_nav_bar package.
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
    final l10n = context.l10n;
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: GNav(
            selectedIndex: selectedIndex,
            gap: 6,
            activeColor: colorScheme.onPrimary,
            iconSize: 22,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: colorScheme.primary,
            color: colorScheme.onSurfaceVariant,
            rippleColor: colorScheme.primary.withValues(alpha: 0.2),
            hoverColor: colorScheme.primary.withValues(alpha: 0.1),
            tabs: [
              GButton(icon: Icons.dashboard_outlined, text: l10n.navDashboard),
              GButton(icon: Icons.checklist_outlined, text: l10n.navTasks),
              GButton(icon: Icons.alarm_outlined, text: l10n.navReminders),
              GButton(icon: Icons.note_outlined, text: l10n.navNotes),
              GButton(icon: Icons.settings_outlined, text: l10n.navSettings),
            ],
            onTabChange: onDestinationSelected,
          ),
        ),
      ),
    );
  }
}
