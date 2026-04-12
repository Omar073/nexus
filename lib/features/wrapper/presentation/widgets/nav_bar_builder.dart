import 'package:flutter/material.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:nexus/features/wrapper/presentation/widgets/nav_bar_wrappers/animated_notch_nav_bar.dart';
import 'package:nexus/features/wrapper/presentation/widgets/nav_bar_wrappers/curved_nav_bar.dart';
import 'package:nexus/features/wrapper/presentation/widgets/nav_bar_wrappers/google_nav_bar_wrapper.dart';
import 'package:nexus/features/wrapper/presentation/widgets/nav_bar_wrappers/rive_animated_nav_bar.dart';
import 'package:nexus/features/wrapper/presentation/widgets/nav_bar_wrappers/standard_nav_bar_wrapper.dart';

/// Selects curved, notch, Google, or Rive nav implementation.
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

      case NavBarStyle.rive:
        return RiveAnimatedNavBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
        );

      case NavBarStyle.standard:
        return StandardNavBarWrapper(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
        );
    }
  }
}
