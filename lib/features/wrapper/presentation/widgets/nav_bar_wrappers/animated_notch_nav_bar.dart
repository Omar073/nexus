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
  int _internalIndex = 0;

  @override
  void initState() {
    super.initState();
    _internalIndex = widget.selectedIndex;
    _controller = NotchBottomBarController(index: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(AnimatedNotchNavBarWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        widget.selectedIndex != _internalIndex) {
      _internalIndex = widget.selectedIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.index = widget.selectedIndex;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedIcon({
    required IconData icon,
    required Color color,
    required bool isActive,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: isActive ? 1.2 : 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Icon(icon, color: color),
        );
      },
    );
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
        bottomBarHeight: 56,
        durationInMilliSeconds: 200,
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
            activeItem: _buildAnimatedIcon(
              icon: Icons.dashboard,
              color: colorScheme.onPrimary,
              isActive: _internalIndex == 0,
            ),
            itemLabel: 'Dashboard',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.checklist_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            activeItem: _buildAnimatedIcon(
              icon: Icons.checklist,
              color: colorScheme.onPrimary,
              isActive: _internalIndex == 1,
            ),
            itemLabel: 'Tasks',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.alarm_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            activeItem: _buildAnimatedIcon(
              icon: Icons.alarm,
              color: colorScheme.onPrimary,
              isActive: _internalIndex == 2,
            ),
            itemLabel: 'Reminders',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.note_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            activeItem: _buildAnimatedIcon(
              icon: Icons.note,
              color: colorScheme.onPrimary,
              isActive: _internalIndex == 3,
            ),
            itemLabel: 'Notes',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.settings_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            activeItem: _buildAnimatedIcon(
              icon: Icons.settings,
              color: colorScheme.onPrimary,
              isActive: _internalIndex == 4,
            ),
            itemLabel: 'Settings',
          ),
        ],
        onTap: (index) {
          setState(() {
            _internalIndex = index;
          });
          widget.onDestinationSelected(index);
        },
      ),
    );
  }
}
