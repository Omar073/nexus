import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:nexus/core/extensions/l10n_x.dart';

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
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedNotchBottomBar(
      notchBottomBarController: _controller,
      color: isDark ? colorScheme.surface : colorScheme.surfaceContainerHighest,
      notchColor: colorScheme.primary,
      showLabel: true,
      showShadow: true,
      showBlurBottomBar: false,
      removeMargins: false,
      bottomBarHeight: 62,
      durationInMilliSeconds: 300,
      kIconSize: 24,
      kBottomRadius: 28,
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
          itemLabel: l10n.navDashboard,
        ),
        BottomBarItem(
          inActiveItem: Icon(
            Icons.checklist_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          activeItem: Icon(Icons.checklist, color: colorScheme.onPrimary),
          itemLabel: l10n.navTasks,
        ),
        BottomBarItem(
          inActiveItem: Icon(
            Icons.alarm_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          activeItem: Icon(Icons.alarm, color: colorScheme.onPrimary),
          itemLabel: l10n.navReminders,
        ),
        BottomBarItem(
          inActiveItem: Icon(
            Icons.note_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          activeItem: Icon(Icons.note, color: colorScheme.onPrimary),
          itemLabel: l10n.navNotes,
        ),
        BottomBarItem(
          inActiveItem: Icon(
            Icons.settings_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          activeItem: Icon(Icons.settings, color: colorScheme.onPrimary),
          itemLabel: l10n.navSettings,
        ),
      ],
      onTap: (index) => widget.onDestinationSelected(index),
    );
  }
}
