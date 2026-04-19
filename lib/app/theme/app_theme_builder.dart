import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nexus/app/theme/app_colors.dart';

ThemeData buildNexusTheme(
  ColorScheme colorScheme,
  Color primary,
  Color secondary, {
  DarkPalette palette = DarkPalette.navy,
}) {
  final isDark = colorScheme.brightness == Brightness.dark;
  final paletteColors = isDark ? AppColors.getDark(palette) : AppColors.light;

  final textTheme = GoogleFonts.interTextTheme(
    isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
  );

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
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
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
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(
      color: paletteColors.outlineVariant,
      thickness: 1,
      space: 1,
    ),
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
    tabBarTheme: TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: paletteColors.onSurfaceVariant,
      indicatorColor: primary,
      labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: paletteColors.surfaceContainer,
      selectedColor: primary.withValues(alpha: 0.2),
      labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
