import 'package:flutter/material.dart';

/// Available navigation bar styles for the app shell.
enum NavBarStyle {
  /// Flutter's default Material 3 NavigationBar
  standard,

  /// Curved navigation bar with floating button effect
  curved,

  /// Navigation bar with animated notch indicator
  notch,

  /// Google-style navigation bar with pill-shaped active indicator
  google,

  /// Bottom navigation bar with animated Rive icons
  rive,
}

/// Extension to provide display names for nav bar styles
extension NavBarStyleExtension on NavBarStyle {
  String get displayName {
    switch (this) {
      case NavBarStyle.standard:
        return 'Standard';
      case NavBarStyle.curved:
        return 'Curved';
      case NavBarStyle.notch:
        return 'Notch';
      case NavBarStyle.google:
        return 'Google';
      case NavBarStyle.rive:
        return 'Rive';
    }
  }

  String get description {
    switch (this) {
      case NavBarStyle.standard:
        return 'Material 3 navigation bar';
      case NavBarStyle.curved:
        return 'Floating curved button';
      case NavBarStyle.notch:
        return 'Animated notch indicator';
      case NavBarStyle.google:
        return 'Pill-shaped active state';
      case NavBarStyle.rive:
        return 'Animated Rive icons';
    }
  }

  /// Returns the height of the navigation bar for this style.
  /// Used for positioning FABs and other elements above the navbar.
  double get height {
    switch (this) {
      case NavBarStyle.standard:
        return 80.0; // Material 3 NavigationBar default
      case NavBarStyle.curved:
        return 65.0; // CurvedNavBarWrapper.height
      case NavBarStyle.notch:
        return 56.0; // AnimatedNotchNavBar bottomBarHeight
      case NavBarStyle.google:
        return 50.0; // GNav + compact wrapper padding (no top/side SafeArea)
      case NavBarStyle.rive:
        return 78.0; // 68 container height + 10 bottom margin
    }
  }

  /// Returns the offset for FAB positioning (navbar height + safe inset + buffer).
  ///
  /// Google, notch, and curved bars sit tighter to the content; they use a
  /// smaller buffer than standard / Rive.
  double fabOffset(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    switch (this) {
      case NavBarStyle.google:
      case NavBarStyle.notch:
      case NavBarStyle.curved:
        return height + bottomInset + 4.0;
      case NavBarStyle.standard:
      case NavBarStyle.rive:
        return height + bottomInset + 8.0;
    }
  }

  /// Returns the padding for scrollable content to avoid navbar overlap.
  double get contentPadding => height + 16.0;
}
