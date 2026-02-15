import 'package:flutter/material.dart';

/// Dark theme palette options
enum DarkPalette {
  /// Navy Dark theme with #101a22 background
  navy,

  /// Pure AMOLED black theme with #000000 background
  amoled,
}

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
  static AppColors of(BuildContext context, {DarkPalette? palette}) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return getDark(palette ?? DarkPalette.navy);
    }
    return light;
  }

  /// Get dark theme colors for a specific palette
  static AppColors getDark(DarkPalette palette) {
    switch (palette) {
      case DarkPalette.navy:
        return darkNavy;
      case DarkPalette.amoled:
        return darkAmoled;
    }
  }

  /// Light theme colors
  static const AppColors light = AppColorsLight();

  /// Dark theme colors (Navy - default)
  static const AppColors darkNavy = AppColorsDarkNavy();

  /// Dark theme colors (AMOLED Black)
  static const AppColors darkAmoled = AppColorsDarkAmoled();

  /// Legacy accessor for dark theme (uses Navy by default)
  static const AppColors dark = AppColorsDarkNavy();
}

/// Light theme color implementation - Nexus Design System
class AppColorsLight implements AppColors {
  const AppColorsLight();

  // Primary - Nexus Blue
  @override
  Color get primary => const Color(0xFF1392EC);
  @override
  Color get primaryContainer => const Color(0xFFD3EAFD);
  @override
  Color get onPrimary => const Color(0xFFFFFFFF);
  @override
  Color get onPrimaryContainer => const Color(0xFF0A4D7A);

  // Secondary - Teal
  @override
  Color get secondary => const Color(0xFF009688);
  @override
  Color get secondaryContainer => const Color(0xFFB2DFDB);
  @override
  Color get onSecondary => const Color(0xFFFFFFFF);
  @override
  Color get onSecondaryContainer => const Color(0xFF00695C);

  // Tertiary - Amber/Orange
  @override
  Color get tertiary => const Color(0xFFFF8F00);
  @override
  Color get tertiaryContainer => const Color(0xFFFFE082);
  @override
  Color get onTertiary => const Color(0xFFFFFFFF);
  @override
  Color get onTertiaryContainer => const Color(0xFFE65100);

  // Surface - Pure white cards on light gray background
  @override
  Color get surface => const Color(0xFFFFFFFF);
  @override
  Color get surfaceContainer => const Color(0xFFF6F7F8);
  @override
  Color get surfaceContainerHigh => const Color(0xFFEEEEEE);
  @override
  Color get surfaceContainerHighest => const Color(0xFFE0E0E0);
  @override
  Color get onSurface => const Color(0xFF0F172A);
  @override
  Color get onSurfaceVariant => const Color(0xFF64748B);

  // Background - Light gray (inspiration: #f6f7f8)
  @override
  Color get background => const Color(0xFFF6F7F8);
  @override
  Color get onBackground => const Color(0xFF0F172A);

  // Error
  @override
  Color get error => const Color(0xFFDC2626);
  @override
  Color get errorContainer => const Color(0xFFFEE2E2);
  @override
  Color get onError => const Color(0xFFFFFFFF);
  @override
  Color get onErrorContainer => const Color(0xFF7F1D1D);

  // Semantic
  @override
  Color get success => const Color(0xFF10B981);
  @override
  Color get successContainer => const Color(0xFFD1FAE5);
  @override
  Color get warning => const Color(0xFFF59E0B);
  @override
  Color get warningContainer => const Color(0xFFFEF3C7);
  @override
  Color get info => const Color(0xFF3B82F6);
  @override
  Color get infoContainer => const Color(0xFFDBEAFE);

  // Outline
  @override
  Color get outline => const Color(0xFFE2E8F0);
  @override
  Color get outlineVariant => const Color(0xFFCBD5E1);

  // Other
  @override
  Color get inverseSurface => const Color(0xFF1E293B);
  @override
  Color get onInverseSurface => const Color(0xFFF1F5F9);
  @override
  Color get inversePrimary => const Color(0xFF60A5FA);
  @override
  Color get scrim => const Color(0xFF000000);
  @override
  Color get shadow => const Color(0xFF000000);
}

/// Dark theme color implementation - Navy palette
/// Background: #101a22, Surface: #1c2227
class AppColorsDarkNavy implements AppColors {
  const AppColorsDarkNavy();

  // Primary - Nexus Blue
  @override
  Color get primary => const Color(0xFF1392EC);
  @override
  Color get primaryContainer => const Color(0xFF0A4D7A);
  @override
  Color get onPrimary => const Color(0xFFFFFFFF);
  @override
  Color get onPrimaryContainer => const Color(0xFFD3EAFD);

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

  // Surface - Navy dark tones
  @override
  Color get surface => const Color(0xFF1C2227);
  @override
  Color get surfaceContainer => const Color(0xFF283239);
  @override
  Color get surfaceContainerHigh => const Color(0xFF323E47);
  @override
  Color get surfaceContainerHighest => const Color(0xFF3D4A54);
  @override
  Color get onSurface => const Color(0xFFFFFFFF);
  @override
  Color get onSurfaceVariant => const Color(0xFF9DADB9);

  // Background - Deep navy (#101a22)
  @override
  Color get background => const Color(0xFF101A22);
  @override
  Color get onBackground => const Color(0xFFFFFFFF);

  // Error
  @override
  Color get error => const Color(0xFFF87171);
  @override
  Color get errorContainer => const Color(0xFF7F1D1D);
  @override
  Color get onError => const Color(0xFF450A0A);
  @override
  Color get onErrorContainer => const Color(0xFFFECACA);

  // Semantic
  @override
  Color get success => const Color(0xFF34D399);
  @override
  Color get successContainer => const Color(0xFF065F46);
  @override
  Color get warning => const Color(0xFFFBBF24);
  @override
  Color get warningContainer => const Color(0xFF92400E);
  @override
  Color get info => const Color(0xFF60A5FA);
  @override
  Color get infoContainer => const Color(0xFF1E40AF);

  // Outline - Subtle white borders
  @override
  Color get outline => const Color(0xFF3B4954);
  @override
  Color get outlineVariant => const Color(0xFF283239);

  // Other
  @override
  Color get inverseSurface => const Color(0xFFE2E8F0);
  @override
  Color get onInverseSurface => const Color(0xFF1E293B);
  @override
  Color get inversePrimary => const Color(0xFF0369A1);
  @override
  Color get scrim => const Color(0xFF000000);
  @override
  Color get shadow => const Color(0xFF000000);
}

/// Dark theme color implementation - AMOLED Black palette
/// Background: #000000, Surface: #121212
class AppColorsDarkAmoled implements AppColors {
  const AppColorsDarkAmoled();

  // Primary - Vibrant Blue for AMOLED contrast
  @override
  Color get primary => const Color(0xFF3B82F6);
  @override
  Color get primaryContainer => const Color(0xFF1E40AF);
  @override
  Color get onPrimary => const Color(0xFFFFFFFF);
  @override
  Color get onPrimaryContainer => const Color(0xFFDBEAFE);

  // Secondary - Teal Light
  @override
  Color get secondary => const Color(0xFF5EEAD4);
  @override
  Color get secondaryContainer => const Color(0xFF115E59);
  @override
  Color get onSecondary => const Color(0xFF042F2E);
  @override
  Color get onSecondaryContainer => const Color(0xFFCCFBF1);

  // Tertiary - Amber Light
  @override
  Color get tertiary => const Color(0xFFFCD34D);
  @override
  Color get tertiaryContainer => const Color(0xFF92400E);
  @override
  Color get onTertiary => const Color(0xFF451A03);
  @override
  Color get onTertiaryContainer => const Color(0xFFFEF3C7);

  // Surface - Pure black with dark gray cards
  @override
  Color get surface => const Color(0xFF121212);
  @override
  Color get surfaceContainer => const Color(0xFF1C1C1E);
  @override
  Color get surfaceContainerHigh => const Color(0xFF252528);
  @override
  Color get surfaceContainerHighest => const Color(0xFF2C2C2E);
  @override
  Color get onSurface => const Color(0xFFFFFFFF);
  @override
  Color get onSurfaceVariant => const Color(0xFFA1A1AA);

  // Background - True black (#000000)
  @override
  Color get background => const Color(0xFF000000);
  @override
  Color get onBackground => const Color(0xFFFFFFFF);

  // Error
  @override
  Color get error => const Color(0xFFF87171);
  @override
  Color get errorContainer => const Color(0xFF7F1D1D);
  @override
  Color get onError => const Color(0xFF450A0A);
  @override
  Color get onErrorContainer => const Color(0xFFFECACA);

  // Semantic
  @override
  Color get success => const Color(0xFF34D399);
  @override
  Color get successContainer => const Color(0xFF065F46);
  @override
  Color get warning => const Color(0xFFFBBF24);
  @override
  Color get warningContainer => const Color(0xFF92400E);
  @override
  Color get info => const Color(0xFF60A5FA);
  @override
  Color get infoContainer => const Color(0xFF1E40AF);

  // Outline - Zinc borders for AMOLED
  @override
  Color get outline => const Color(0xFF27272A);
  @override
  Color get outlineVariant => const Color(0xFF3F3F46);

  // Other
  @override
  Color get inverseSurface => const Color(0xFFFAFAFA);
  @override
  Color get onInverseSurface => const Color(0xFF18181B);
  @override
  Color get inversePrimary => const Color(0xFF1D4ED8);
  @override
  Color get scrim => const Color(0xFF000000);
  @override
  Color get shadow => const Color(0xFF000000);
}
