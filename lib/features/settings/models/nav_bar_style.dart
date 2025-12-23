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
    }
  }
}
