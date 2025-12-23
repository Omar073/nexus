import 'package:flutter/material.dart';

/// Centralized color definitions for the Nexus app.
/// Access colors via [AppColors.of(context)] for theme-aware colors.
abstract class AppColors {
  // ============ Primary Colors ============
  /// Main brand color used for key UI elements
  Color get primary;

  /// Lighter variant of primary for containers/backgrounds
  Color get primaryContainer;

  /// Text/icon color on primary
  Color get onPrimary;

  /// Text/icon color on primary container
  Color get onPrimaryContainer;

  // ============ Secondary Colors ============
  /// Accent color for secondary actions
  Color get secondary;

  /// Lighter variant of secondary
  Color get secondaryContainer;

  /// Text/icon color on secondary
  Color get onSecondary;

  /// Text/icon color on secondary container
  Color get onSecondaryContainer;

  // ============ Tertiary Colors ============
  /// Third accent color for additional emphasis
  Color get tertiary;

  /// Lighter variant of tertiary
  Color get tertiaryContainer;

  /// Text/icon color on tertiary
  Color get onTertiary;

  /// Text/icon color on tertiary container
  Color get onTertiaryContainer;

  // ============ Surface Colors ============
  /// Background for cards, sheets, menus
  Color get surface;

  /// Slightly elevated surface
  Color get surfaceContainer;

  /// Higher elevation surface
  Color get surfaceContainerHigh;

  /// Highest elevation surface
  Color get surfaceContainerHighest;

  /// Text/icon color on surface
  Color get onSurface;

  /// Variant text color on surface (secondary text)
  Color get onSurfaceVariant;

  // ============ Background Colors ============
  /// Main scaffold/page background
  Color get background;

  /// Text/icon color on background
  Color get onBackground;

  // ============ Semantic Colors ============
  /// Error/destructive actions
  Color get error;

  /// Error container background
  Color get errorContainer;

  /// Text/icon color on error
  Color get onError;

  /// Text/icon color on error container
  Color get onErrorContainer;

  /// Success/positive states
  Color get success;

  /// Success container background
  Color get successContainer;

  /// Warning/caution states
  Color get warning;

  /// Warning container background
  Color get warningContainer;

  /// Info/neutral states
  Color get info;

  /// Info container background
  Color get infoContainer;

  // ============ Outline Colors ============
  /// Primary outline/border color
  Color get outline;

  /// Subtle outline for dividers
  Color get outlineVariant;

  // ============ Other Colors ============
  /// Inverse surface for chips, snackbars
  Color get inverseSurface;

  /// Text/icon color on inverse surface
  Color get onInverseSurface;

  /// Primary color on inverse surface
  Color get inversePrimary;

  /// Scrim/overlay color
  Color get scrim;

  /// Shadow color
  Color get shadow;

  /// Get theme-aware colors from context
  static AppColors of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }

  /// Light theme colors
  static const AppColors light = AppColorsLight();

  /// Dark theme colors
  static const AppColors dark = AppColorsDark();
}

/// Light theme color implementation
class AppColorsLight implements AppColors {
  const AppColorsLight();

  // Primary - Deep Indigo
  @override
  Color get primary => const Color(0xFF3F51B5);
  @override
  Color get primaryContainer => const Color(0xFFC5CAE9);
  @override
  Color get onPrimary => const Color(0xFFFFFFFF);
  @override
  Color get onPrimaryContainer => const Color(0xFF1A237E);

  // Secondary - Teal
  @override
  Color get secondary => const Color(0xFF009688);
  @override
  Color get secondaryContainer => const Color(0xFFB2DFDB);
  @override
  Color get onSecondary => const Color(0xFFFFFFFF);
  @override
  Color get onSecondaryContainer => const Color(0xFF00695C);

  // Tertiary - Amber
  @override
  Color get tertiary => const Color(0xFFFF8F00);
  @override
  Color get tertiaryContainer => const Color(0xFFFFE082);
  @override
  Color get onTertiary => const Color(0xFFFFFFFF);
  @override
  Color get onTertiaryContainer => const Color(0xFFE65100);

  // Surface
  @override
  Color get surface => const Color(0xFFFFFFFF);
  @override
  Color get surfaceContainer => const Color(0xFFF5F5F5);
  @override
  Color get surfaceContainerHigh => const Color(0xFFEEEEEE);
  @override
  Color get surfaceContainerHighest => const Color(0xFFE0E0E0);
  @override
  Color get onSurface => const Color(0xFF1C1B1F);
  @override
  Color get onSurfaceVariant => const Color(0xFF49454F);

  // Background
  @override
  Color get background => const Color(0xFFFAFAFA);
  @override
  Color get onBackground => const Color(0xFF1C1B1F);

  // Error
  @override
  Color get error => const Color(0xFFB00020);
  @override
  Color get errorContainer => const Color(0xFFFFDAD6);
  @override
  Color get onError => const Color(0xFFFFFFFF);
  @override
  Color get onErrorContainer => const Color(0xFF410002);

  // Semantic
  @override
  Color get success => const Color(0xFF4CAF50);
  @override
  Color get successContainer => const Color(0xFFC8E6C9);
  @override
  Color get warning => const Color(0xFFFFC107);
  @override
  Color get warningContainer => const Color(0xFFFFF8E1);
  @override
  Color get info => const Color(0xFF2196F3);
  @override
  Color get infoContainer => const Color(0xFFBBDEFB);

  // Outline
  @override
  Color get outline => const Color(0xFF79747E);
  @override
  Color get outlineVariant => const Color(0xFFCAC4D0);

  // Other
  @override
  Color get inverseSurface => const Color(0xFF313033);
  @override
  Color get onInverseSurface => const Color(0xFFF4EFF4);
  @override
  Color get inversePrimary => const Color(0xFF9FA8DA);
  @override
  Color get scrim => const Color(0xFF000000);
  @override
  Color get shadow => const Color(0xFF000000);
}

/// Dark theme color implementation
class AppColorsDark implements AppColors {
  const AppColorsDark();

  // Primary - Light Indigo
  @override
  Color get primary => const Color(0xFF9FA8DA);
  @override
  Color get primaryContainer => const Color(0xFF303F9F);
  @override
  Color get onPrimary => const Color(0xFF1A237E);
  @override
  Color get onPrimaryContainer => const Color(0xFFC5CAE9);

  // Secondary - Teal Light
  @override
  Color get secondary => const Color(0xFF80CBC4);
  @override
  Color get secondaryContainer => const Color(0xFF00695C);
  @override
  Color get onSecondary => const Color(0xFF003731);
  @override
  Color get onSecondaryContainer => const Color(0xFFB2DFDB);

  // Tertiary - Amber Light
  @override
  Color get tertiary => const Color(0xFFFFD54F);
  @override
  Color get tertiaryContainer => const Color(0xFFE65100);
  @override
  Color get onTertiary => const Color(0xFF3E2723);
  @override
  Color get onTertiaryContainer => const Color(0xFFFFE082);

  // Surface - Dark grays
  @override
  Color get surface => const Color(0xFF1E1E1E);
  @override
  Color get surfaceContainer => const Color(0xFF252525);
  @override
  Color get surfaceContainerHigh => const Color(0xFF2D2D2D);
  @override
  Color get surfaceContainerHighest => const Color(0xFF363636);
  @override
  Color get onSurface => const Color(0xFFE6E1E5);
  @override
  Color get onSurfaceVariant => const Color(0xFFCAC4D0);

  // Background
  @override
  Color get background => const Color(0xFF121212);
  @override
  Color get onBackground => const Color(0xFFE6E1E5);

  // Error
  @override
  Color get error => const Color(0xFFCF6679);
  @override
  Color get errorContainer => const Color(0xFF93000A);
  @override
  Color get onError => const Color(0xFF690005);
  @override
  Color get onErrorContainer => const Color(0xFFFFDAD6);

  // Semantic
  @override
  Color get success => const Color(0xFF81C784);
  @override
  Color get successContainer => const Color(0xFF2E7D32);
  @override
  Color get warning => const Color(0xFFFFD54F);
  @override
  Color get warningContainer => const Color(0xFFF57F17);
  @override
  Color get info => const Color(0xFF64B5F6);
  @override
  Color get infoContainer => const Color(0xFF1565C0);

  // Outline
  @override
  Color get outline => const Color(0xFF938F99);
  @override
  Color get outlineVariant => const Color(0xFF49454F);

  // Other
  @override
  Color get inverseSurface => const Color(0xFFE6E1E5);
  @override
  Color get onInverseSurface => const Color(0xFF313033);
  @override
  Color get inversePrimary => const Color(0xFF3F51B5);
  @override
  Color get scrim => const Color(0xFF000000);
  @override
  Color get shadow => const Color(0xFF000000);
}
