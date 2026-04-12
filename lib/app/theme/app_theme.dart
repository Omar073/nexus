import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nexus/app/theme/app_colors.dart';

/// Builds [ThemeData] for light/dark from settings and seeds.
class AppTheme {
  /// Resolves [ThemeMode.system] via [MediaQuery.platformBrightnessOf] so the
  /// result matches the OS appearance. Use a [context] under [MaterialApp].
  static ThemeData fromUserSettings(
    BuildContext context, {
    required ThemeMode themeMode,
    required Color? lightPrimary,
    required Color? lightSecondary,
    required Color? darkPrimary,
    required Color? darkSecondary,
    required DarkPalette darkPalette,
  }) {
    final brightness = switch (themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
    return brightness == Brightness.dark
        ? dark(
            customPrimary: darkPrimary,
            customSecondary: darkSecondary,
            palette: darkPalette,
          )
        : light(customPrimary: lightPrimary, customSecondary: lightSecondary);
  }

  /// Builds light theme
  static ThemeData light({Color? customPrimary, Color? customSecondary}) {
    // Nexus design system defaults
    const defaultPrimary = Color(0xFF1392EC); // Nexus Blue
    const defaultSecondary = Color(0xFF009688); // Teal

    final primary = customPrimary ?? defaultPrimary;
    final secondary = customSecondary ?? defaultSecondary;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: secondary,
      brightness: Brightness.light,
      // Nexus light background: #f6f7f8
      surface: const Color(0xFFF6F7F8),
    );

    return _buildTheme(colorScheme, primary, secondary);
  }

  /// Builds dark theme with palette selection
  static ThemeData dark({
    Color? customPrimary,
    Color? customSecondary,
    DarkPalette palette = DarkPalette.navy,
  }) {
    // Get palette-specific defaults
    final paletteColors = AppColors.getDark(palette);

    final primary = customPrimary ?? paletteColors.primary;
    final secondary = customSecondary ?? paletteColors.secondary;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: secondary,
      brightness: Brightness.dark,
      surface: paletteColors.background,
    );

    return _buildTheme(colorScheme, primary, secondary, palette: palette);
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    Color primary,
    Color secondary, {
    DarkPalette palette = DarkPalette.navy,
  }) {
    final isDark = colorScheme.brightness == Brightness.dark;

    // Get palette-specific colors for dark mode
    final paletteColors = isDark ? AppColors.getDark(palette) : AppColors.light;

    // Base text theme with Inter
    final textTheme = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    // Apply color to text theme
    final coloredTextTheme = textTheme.apply(
      bodyColor: isDark
          ? Colors.white.withValues(alpha: 0.9)
          : paletteColors.onSurface,
      displayColor: isDark ? Colors.white : paletteColors.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.copyWith(
        primary: primary,
        secondary: secondary,
        surface: paletteColors.surface,
        onSurface: paletteColors.onSurface,
        onSurfaceVariant: paletteColors.onSurfaceVariant,
        outline: paletteColors.outline,
        outlineVariant: paletteColors.outlineVariant,
      ),
      scaffoldBackgroundColor: paletteColors.background,
      textTheme: coloredTextTheme,

      // Minimal AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : paletteColors.onSurface,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : paletteColors.onSurface,
          size: 24,
        ),
      ),

      // Modern Cards - palette-aware styling
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark
              ? BorderSide(color: paletteColors.outline.withValues(alpha: 0.3))
              : BorderSide(color: paletteColors.outline),
        ),
        color: paletteColors.surface,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: primary, width: 1.5),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paletteColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: paletteColors.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: paletteColors.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: paletteColors.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: paletteColors.onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: paletteColors.onSurfaceVariant,
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? paletteColors.surfaceContainer
            : const Color(0xFF1E293B),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Floating Action Button - Nexus style with shadow glow
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: paletteColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? paletteColors.background : Colors.white,
        elevation: 0,
        indicatorColor: primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: primary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.normal,
            color: paletteColors.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 24);
          }
          return IconThemeData(color: paletteColors.onSurfaceVariant, size: 24);
        }),
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: paletteColors.onSurfaceVariant,
        indicatorColor: primary,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: paletteColors.surfaceContainer,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
