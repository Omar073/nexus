import 'package:flutter/material.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/settings/presentation/utils/nav_icon_mapper.dart';
import 'package:provider/provider.dart';

/// Hosts the custom compact standard bottom navigation bar.
///
/// Based on a design by the user to achieve perfect vertical centering
/// at a compact 50px height, bypassing Material 3 constraints.
class StandardNavBarWrapper extends StatelessWidget {
  const StandardNavBarWrapper({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<SettingsController>();
    final navTheme = theme.navigationBarTheme;
    final selections = controller.navigationIcons;

    return SafeArea(
      top: false,
      child: Container(
        height: 50,
        decoration: BoxDecoration(color: navTheme.backgroundColor),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _NavItem(
              page: 'dashboard',
              label: 'Dashboard',
              isSelected: selectedIndex == 0,
              onTap: () => onDestinationSelected(0),
              navTheme: navTheme,
              selections: selections,
            ),
            _NavItem(
              page: 'tasks',
              label: 'Tasks',
              isSelected: selectedIndex == 1,
              onTap: () => onDestinationSelected(1),
              navTheme: navTheme,
              selections: selections,
            ),
            _NavItem(
              page: 'reminders',
              label: 'Reminders',
              isSelected: selectedIndex == 2,
              onTap: () => onDestinationSelected(2),
              navTheme: navTheme,
              selections: selections,
            ),
            _NavItem(
              page: 'notes',
              label: 'Notes',
              isSelected: selectedIndex == 3,
              onTap: () => onDestinationSelected(3),
              navTheme: navTheme,
              selections: selections,
            ),
            _NavItem(
              page: 'settings',
              label: 'Settings',
              isSelected: selectedIndex == 4,
              onTap: () => onDestinationSelected(4),
              navTheme: navTheme,
              selections: selections,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.page,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.navTheme,
    required this.selections,
  });

  final String page;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final NavigationBarThemeData navTheme;
  final Map<String, int> selections;

  @override
  Widget build(BuildContext context) {
    // Resolve icons from the mapper
    final icon = NavIconMapper.getIconForPage(page, selections);
    final selectedIcon = NavIconMapper.getIconForPage(
      page,
      selections,
      isSelected: true,
    );

    // Resolve styles from the NavigationBarTheme
    final iconTheme = navTheme.iconTheme?.resolve({
      if (isSelected) WidgetState.selected else WidgetState.disabled,
    });
    final textStyle = navTheme.labelTextStyle?.resolve({
      if (isSelected) WidgetState.selected else WidgetState.disabled,
    });

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? navTheme.indicatorColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: iconTheme?.color,
                size: 23,
              ),
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: textStyle?.copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
