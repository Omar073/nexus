import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:nexus/core/extensions/l10n_x.dart';

/// Curved navigation bar wrapper using curved_labeled_navigation_bar package.
class CurvedNavBarWrapper extends StatelessWidget {
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
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    return CurvedNavigationBar(
      index: selectedIndex,
      height: 65,
      backgroundColor: Colors.transparent,
      color: isDark ? colorScheme.surface : colorScheme.surfaceContainerHighest,
      buttonBackgroundColor: colorScheme.primary,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 400),
      items: [
        CurvedNavigationBarItem(
          child: Icon(
            selectedIndex == 0 ? Icons.dashboard : Icons.dashboard_outlined,
            color: selectedIndex == 0
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
          label: l10n.navDashboard,
          labelStyle: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        CurvedNavigationBarItem(
          child: Icon(
            selectedIndex == 1 ? Icons.checklist : Icons.checklist_outlined,
            color: selectedIndex == 1
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
          label: l10n.navTasks,
          labelStyle: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        CurvedNavigationBarItem(
          child: Icon(
            selectedIndex == 2 ? Icons.alarm : Icons.alarm_outlined,
            color: selectedIndex == 2
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
          label: l10n.navReminders,
          labelStyle: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        CurvedNavigationBarItem(
          child: Icon(
            selectedIndex == 3 ? Icons.note : Icons.note_outlined,
            color: selectedIndex == 3
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
          label: l10n.navNotes,
          labelStyle: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        CurvedNavigationBarItem(
          child: Icon(
            selectedIndex == 4 ? Icons.settings : Icons.settings_outlined,
            color: selectedIndex == 4
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
          label: l10n.navSettings,
          labelStyle: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
      onTap: onDestinationSelected,
    );
  }
}
