/// Asset path, artboard, and state machine for one Rive icon.
class RiveModel {
  const RiveModel({
    required this.src,
    required this.artboard,
    required this.stateMachineName,
  });

  /// Path to the .riv asset file.
  final String src;

  /// Name of the artboard inside the .riv file.
  final String artboard;

  /// Name of the state machine attached to the artboard.
  final String stateMachineName;
}

/// Tab title paired with a [RiveModel] for the Rive nav bar.
class RiveNavItem {
  const RiveNavItem({required this.title, required this.rive});

  /// Label shown below/above the icon.
  final String title;

  /// The Rive animation to render for this item.
  final RiveModel rive;
}

/// Source path for the animated icon set asset.
const String _animatedIconSrc =
    'assets/1298-2487-animated-icon-set-1-color.riv';

/// Default state machine name used across all artboards.
const String _stateMachine = 'State Machine 1';

/// All items displayed in the Rive-animated bottom navigation bar.
///
/// Each item maps a tab label to an artboard from the .riv file.
const List<RiveNavItem> riveBottomNavItems = [
  RiveNavItem(
    title: 'Dashboard',
    rive: RiveModel(
      src: _animatedIconSrc,
      artboard: 'HOME',
      stateMachineName: _stateMachine,
    ),
  ),
  RiveNavItem(
    title: 'Tasks',
    rive: RiveModel(
      src: _animatedIconSrc,
      artboard: 'SEARCH',
      stateMachineName: _stateMachine,
    ),
  ),
  RiveNavItem(
    title: 'Reminders',
    rive: RiveModel(
      src: _animatedIconSrc,
      artboard: 'BELL',
      stateMachineName: _stateMachine,
    ),
  ),
  RiveNavItem(
    title: 'Notes',
    rive: RiveModel(
      src: _animatedIconSrc,
      artboard: 'CHAT',
      stateMachineName: _stateMachine,
    ),
  ),
  RiveNavItem(
    title: 'Settings',
    rive: RiveModel(
      src: _animatedIconSrc,
      artboard: 'SETTINGS',
      stateMachineName: _stateMachine,
    ),
  ),
];
