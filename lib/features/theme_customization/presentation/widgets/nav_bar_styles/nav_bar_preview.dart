import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/wrapper/presentation/widgets/nav_bar_wrappers/curved_nav_bar.dart';
import 'package:nexus/features/wrapper/presentation/widgets/nav_bar_wrappers/rive_animated_nav_bar.dart';
import 'package:provider/provider.dart';

import 'google_nav_bar_preview.dart';
import 'material_nav_bar_preview.dart';
import 'notch_nav_bar_preview.dart';

/// Interactive preview of the selected navigation bar style.
/// Taps change the highlighted tab only; they do not navigate.
class NavBarPreview extends StatefulWidget {
  const NavBarPreview({super.key, required this.style, required this.isLight});

  final NavBarStyle style;
  final bool isLight;

  @override
  State<NavBarPreview> createState() => _NavBarPreviewState();
}

class _NavBarPreviewState extends State<NavBarPreview> {
  int _selectedIndex = 0;
  late final NotchBottomBarController _notchController =
      NotchBottomBarController(index: 0);

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
    final selections = settings.navigationIcons;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isLight ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _PreviewBody(
        style: widget.style,
        selectedIndex: _selectedIndex,
        onTap: _onTap,
        primary: primary,
        backgroundColor: bgColor,
        inactiveColor: inactiveColor,
        selections: selections,
        notchController: _notchController,
        notchItemLabelStyle: TextStyle(
          fontSize: 10,
          color: widget.isLight ? Colors.black54 : Colors.white54,
        ),
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.style,
    required this.selectedIndex,
    required this.onTap,
    required this.primary,
    required this.backgroundColor,
    required this.inactiveColor,
    required this.selections,
    required this.notchController,
    required this.notchItemLabelStyle,
  });

  final NavBarStyle style;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Color primary;
  final Color backgroundColor;
  final Color inactiveColor;
  final Map<String, int> selections;
  final NotchBottomBarController notchController;
  final TextStyle notchItemLabelStyle;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case NavBarStyle.standard:
        return MaterialNavBarPreview(
          selectedIndex: selectedIndex,
          onDestinationSelected: onTap,
          primary: primary,
          backgroundColor: backgroundColor,
          inactiveColor: inactiveColor,
          selections: selections,
        );
      case NavBarStyle.google:
        return GoogleNavBarPreview(
          selectedIndex: selectedIndex,
          onTabChange: onTap,
          primary: primary,
          backgroundColor: backgroundColor,
          inactiveColor: inactiveColor,
          selections: selections,
        );
      case NavBarStyle.curved:
        return SizedBox(
          height: 90,
          child: CurvedNavBarWrapper(
            selectedIndex: selectedIndex,
            onDestinationSelected: onTap,
          ),
        );
      case NavBarStyle.notch:
        return SizedBox(
          height: 100,
          child: NotchNavBarPreview(
            notchBottomBarController: notchController,
            onTap: onTap,
            primary: primary,
            backgroundColor: backgroundColor,
            inactiveColor: inactiveColor,
            itemLabelStyle: notchItemLabelStyle,
            selections: selections,
          ),
        );
      case NavBarStyle.rive:
        return SizedBox(
          height: 80,
          child: RiveAnimatedNavBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onTap,
          ),
        );
    }
  }
}
