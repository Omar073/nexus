import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:nexus/features/wrapper/presentation/widgets/nav_bar_wrappers/curved_nav_bar.dart';
import 'package:provider/provider.dart';

/// Interactive preview of the selected navigation bar style.
/// Users can tap different buttons but it doesn't navigate anywhere.
class NavBarPreview extends StatefulWidget {
  const NavBarPreview({super.key, required this.style, required this.isLight});

  final NavBarStyle style;
  final bool isLight;

  @override
  State<NavBarPreview> createState() => _NavBarPreviewState();
}

class _NavBarPreviewState extends State<NavBarPreview> {
  int _selectedIndex = 0;
  late NotchBottomBarController _notchController;

  @override
  void initState() {
    super.initState();
    _notchController = NotchBottomBarController(index: 0);
  }

  @override
  void dispose() {
    _notchController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    setState(() => _selectedIndex = index);
    if (widget.style == NavBarStyle.notch) {
      _notchController.jumpTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final primary = widget.isLight
        ? (settings.lightColors.primary ?? const Color(0xFF3F51B5))
        : (settings.darkColors.primary ?? const Color(0xFF9FA8DA));
    final bgColor = widget.isLight ? Colors.white : const Color(0xFF1E1E1E);
    final inactiveColor = widget.isLight ? Colors.black54 : Colors.white54;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isLight ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildNavBar(primary, bgColor, inactiveColor),
    );
  }

  Widget _buildNavBar(Color primary, Color bgColor, Color inactiveColor) {
    switch (widget.style) {
      case NavBarStyle.standard:
        return NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTap,
          backgroundColor: bgColor,
          indicatorColor: primary.withValues(alpha: 0.2),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: inactiveColor),
              selectedIcon: Icon(Icons.dashboard, color: primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined, color: inactiveColor),
              selectedIcon: Icon(Icons.checklist, color: primary),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: inactiveColor),
              selectedIcon: Icon(Icons.settings, color: primary),
              label: 'Settings',
            ),
          ],
        );

      case NavBarStyle.google:
        return Container(
          color: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: GNav(
            selectedIndex: _selectedIndex,
            onTabChange: _onTap,
            gap: 8,
            activeColor: primary,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            tabBackgroundColor: primary.withValues(alpha: 0.15),
            color: inactiveColor,
            tabs: const [
              GButton(icon: Icons.dashboard, text: 'Dashboard'),
              GButton(icon: Icons.checklist, text: 'Tasks'),
              GButton(icon: Icons.settings, text: 'Settings'),
            ],
          ),
        );

      case NavBarStyle.curved:
        return SizedBox(
          height: 90,
          child: CurvedNavBarWrapper(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onTap,
          ),
        );

      case NavBarStyle.notch:
        return SizedBox(
          height: 100,
          child: AnimatedNotchBottomBar(
            notchBottomBarController: _notchController,
            onTap: _onTap,
            color: bgColor,
            showLabel: true,
            textOverflow: TextOverflow.visible,
            maxLine: 1,
            shadowElevation: 5,
            kBottomRadius: 28.0,
            notchColor: primary,
            removeMargins: false,
            showShadow: false,
            durationInMilliSeconds: 300,
            itemLabelStyle: TextStyle(
              fontSize: 10,
              color: widget.isLight ? Colors.black54 : Colors.white54,
            ),
            elevation: 1,
            kIconSize: 24.0,
            bottomBarItems: [
              BottomBarItem(
                inActiveItem: Icon(
                  Icons.dashboard_outlined,
                  color: inactiveColor,
                ),
                activeItem: const Icon(Icons.dashboard, color: Colors.white),
                itemLabel: 'Dashboard',
              ),
              BottomBarItem(
                inActiveItem: Icon(
                  Icons.checklist_outlined,
                  color: inactiveColor,
                ),
                activeItem: const Icon(Icons.checklist, color: Colors.white),
                itemLabel: 'Tasks',
              ),
              BottomBarItem(
                inActiveItem: Icon(
                  Icons.settings_outlined,
                  color: inactiveColor,
                ),
                activeItem: const Icon(Icons.settings, color: Colors.white),
                itemLabel: 'Settings',
              ),
            ],
          ),
        );
    }
  }
}
