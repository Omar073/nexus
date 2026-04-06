import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:nexus/features/wrapper/presentation/widgets/nav_bar_wrappers/rive_model.dart';
import 'package:rive/rive.dart';

/// Bottom navigation bar with animated Rive icons.
///
/// Each tab icon is a Rive artboard driven by a state machine.
/// Tapping an icon triggers the `active` boolean input, which
/// plays the artboard's active animation for one second before
/// returning to idle.
class RiveAnimatedNavBar extends StatefulWidget {
  const RiveAnimatedNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<RiveAnimatedNavBar> createState() => _RiveAnimatedNavBarState();
}

class _RiveAnimatedNavBarState extends State<RiveAnimatedNavBar> {
  /// Widget controllers (one per icon).
  final List<RiveWidgetController> _controllers = [];

  /// The `active` boolean input for each icon's state machine.
  // ignore: deprecated_member_use
  final List<BooleanInput?> _inputs = [];

  /// Whether the Rive file has been loaded and parsed.
  bool _isLoaded = false;

  /// The currently selected tab index (local state).
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _loadRiveFile();
  }

  @override
  void didUpdateWidget(RiveAnimatedNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
  }

  Future<void> _loadRiveFile() async {
    try {
      final src = riveBottomNavItems.first.rive.src;
      final file = await File.asset(src, riveFactory: Factory.flutter);
      if (file == null || !mounted) return;

      for (final item in riveBottomNavItems) {
        final controller = RiveWidgetController(
          file,
          artboardSelector: ArtboardSelector.byName(item.rive.artboard),
          // Use default state machine (name varies per .riv).
          stateMachineSelector: StateMachineSelector.byDefault(),
        );

        // ignore: deprecated_member_use
        final input = controller.stateMachine.boolean('active');
        _controllers.add(controller);
        _inputs.add(input);
      }

      if (mounted) {
        setState(() => _isLoaded = true);
      }
    } catch (e) {
      mDebugPrint('[RiveAnimatedNavBar] Failed to load: $e');
    }
  }

  void _animateIcon(int index) {
    final input = _inputs[index];
    if (input == null) return;
    // ignore: deprecated_member_use
    input.value = true;
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // ignore: deprecated_member_use
        input.value = false;
      }
    });
  }

  void _onTap(int index) {
    _animateIcon(index);
    setState(() => _selectedIndex = index);
    widget.onDestinationSelected(index);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const SizedBox(height: 68);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surface
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:
                  (isDark
                          ? colorScheme.surface
                          : colorScheme.surfaceContainerHighest)
                      .withValues(alpha: 0.3),
              offset: const Offset(0, 20),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(riveBottomNavItems.length, (index) {
            final isActive = _selectedIndex == index;
            return GestureDetector(
              onTap: () => _onTap(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AnimatedBar(isActive: isActive),
                  const SizedBox(height: 2),
                  Opacity(
                    opacity: isActive ? 1.0 : 0.5,
                    child: SizedBox(
                      height: 36,
                      width: 36,
                      child: RiveWidget(controller: _controllers[index]),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Animated bar indicator shown above the selected icon.
class _AnimatedBar extends StatelessWidget {
  const _AnimatedBar({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 4,
      width: isActive ? 20 : 0,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
