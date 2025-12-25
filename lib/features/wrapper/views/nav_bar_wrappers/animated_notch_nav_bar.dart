import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';

/// Animated notch navigation bar wrapper using animated_notch_bottom_bar package.
class AnimatedNotchNavBarWrapper extends StatefulWidget {
  const AnimatedNotchNavBarWrapper({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<AnimatedNotchNavBarWrapper> createState() =>
      _AnimatedNotchNavBarWrapperState();
}

class _AnimatedNotchNavBarWrapperState
    extends State<AnimatedNotchNavBarWrapper> {
  late NotchBottomBarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotchBottomBarController(index: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(AnimatedNotchNavBarWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller when external index changes
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _controller.jumpTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: AnimatedNotchBottomBar(
        notchBottomBarController: _controller,
        color: isDark
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest,
        notchColor: colorScheme.primary,
        showLabel: true,
        textOverflow: TextOverflow.visible,
        maxLine: 1,
        shadowElevation: 0,
        showShadow: false,
        showBlurBottomBar: false,
        removeMargins: true,
        bottomBarWidth: MediaQuery.of(context).size.width,
        bottomBarHeight: 62,
        durationInMilliSeconds: 300,
        kIconSize: 24.0,
        kBottomRadius: 0,
        elevation: 0,
        itemLabelStyle: TextStyle(
          fontSize: 10,
          color: colorScheme.onSurfaceVariant,
        ),
        bottomBarItems: [
          BottomBarItem(
            inActiveItem: Icon(
              Icons.dashboard_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            activeItem: Icon(Icons.dashboard, color: colorScheme.onPrimary),
            itemLabel: 'Dashboard',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.checklist_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            activeItem: Icon(Icons.checklist, color: colorScheme.onPrimary),
            itemLabel: 'Tasks',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.alarm_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            activeItem: Icon(Icons.alarm, color: colorScheme.onPrimary),
            itemLabel: 'Reminders',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.note_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            activeItem: Icon(Icons.note, color: colorScheme.onPrimary),
            itemLabel: 'Notes',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.settings_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            activeItem: Icon(Icons.settings, color: colorScheme.onPrimary),
            itemLabel: 'Settings',
          ),
        ],
        onTap: (index) {
          // The animation happens internally via the controller
          // We just need to notify the parent about the selection
          widget.onDestinationSelected(index);
        },
      ),
    );
  }
}
