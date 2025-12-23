import 'package:flutter/material.dart';
import 'package:nexus/core/extensions/l10n_x.dart';
import 'package:nexus/features/settings/models/nav_bar_style.dart';
import 'package:nexus/features/wrapper/views/nav_bar_wrappers/animated_notch_nav_bar.dart';
import 'package:nexus/features/wrapper/views/nav_bar_wrappers/curved_nav_bar.dart';
import 'package:nexus/features/wrapper/views/nav_bar_wrappers/google_nav_bar_wrapper.dart';

/// Builds the appropriate navigation bar based on the selected style.
class NavBarBuilder extends StatelessWidget {
  const NavBarBuilder({
    super.key,
    required this.style,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final NavBarStyle style;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    switch (style) {
      case NavBarStyle.curved:
        return CurvedNavBarWrapper(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
        );

      case NavBarStyle.notch:
        return AnimatedNotchNavBarWrapper(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
        );

      case NavBarStyle.google:
        return GoogleNavBarWrapper(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
        );

      case NavBarStyle.standard:
        return NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: l10n.navDashboard,
            ),
            NavigationDestination(
              icon: const Icon(Icons.checklist_outlined),
              selectedIcon: const Icon(Icons.checklist),
              label: l10n.navTasks,
            ),
            NavigationDestination(
              icon: const Icon(Icons.alarm_outlined),
              selectedIcon: const Icon(Icons.alarm),
              label: l10n.navReminders,
            ),
            NavigationDestination(
              icon: const Icon(Icons.note_outlined),
              selectedIcon: const Icon(Icons.note),
              label: l10n.navNotes,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l10n.navSettings,
            ),
          ],
        );
    }
  }
}
