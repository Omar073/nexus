import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:nexus/features/settings/presentation/utils/nav_icon_mapper.dart';

import 'nav_shell_slots.dart';

/// Notch bottom bar for [NavBarStyle.notch] preview.
class NotchNavBarPreview extends StatelessWidget {
  const NotchNavBarPreview({
    super.key,
    required this.notchBottomBarController,
    required this.onTap,
    required this.primary,
    required this.backgroundColor,
    required this.inactiveColor,
    required this.itemLabelStyle,
    required this.selections,
  });

  final NotchBottomBarController notchBottomBarController;
  final ValueChanged<int> onTap;
  final Color primary;
  final Color backgroundColor;
  final Color inactiveColor;
  final TextStyle itemLabelStyle;
  final Map<String, int> selections;

  @override
  Widget build(BuildContext context) {
    return AnimatedNotchBottomBar(
      notchBottomBarController: notchBottomBarController,
      onTap: onTap,
      color: backgroundColor,
      showLabel: true,
      textOverflow: TextOverflow.visible,
      maxLine: 1,
      shadowElevation: 5,
      kBottomRadius: 28.0,
      notchColor: primary,
      removeMargins: false,
      showShadow: false,
      durationInMilliSeconds: 300,
      itemLabelStyle: itemLabelStyle,
      elevation: 1,
      kIconSize: 24.0,
      bottomBarItems: [
        for (var i = 0; i < kNavShellPageIds.length; i++)
          BottomBarItem(
            inActiveItem: Icon(
              NavIconMapper.getIconForPage(kNavShellPageIds[i], selections),
              color: inactiveColor,
            ),
            activeItem: Icon(
              NavIconMapper.getIconForPage(
                kNavShellPageIds[i],
                selections,
                isSelected: true,
              ),
              color: Colors.white,
            ),
            itemLabel: kNavShellLabels[i],
          ),
      ],
    );
  }
}
