import 'package:flutter/material.dart';
import 'package:nexus/app/theme/app_colors.dart';
import 'package:nexus/features/categories/domain/category_sort_option.dart';
import 'package:nexus/features/settings/data/models/color_preset.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:nexus/features/settings/domain/entities/color_preset_entity.dart';
import 'package:nexus/features/tasks/domain/task_sort_option.dart';

ThemeMode mapThemeMode(String raw) =>
    raw == 'light' ? ThemeMode.light : ThemeMode.dark;

String themeModeToStorage(ThemeMode mode) =>
    mode == ThemeMode.light ? 'light' : 'dark';

NavBarStyle mapNavBarStyle(String raw) => NavBarStyle.values.firstWhere(
  (s) => s.name == raw,
  orElse: () => NavBarStyle.standard,
);

DarkPalette mapDarkPalette(String raw) =>
    raw == 'amoled' ? DarkPalette.amoled : DarkPalette.navy;

TaskSortOption mapTaskSortOption(String raw) =>
    TaskSortOption.values.firstWhere(
      (o) => o.name == raw,
      orElse: () => TaskSortOption.recentlyModified,
    );

CategorySortOption mapCategorySortOption(String raw) =>
    CategorySortOption.values.firstWhere(
      (o) => o.name == raw,
      orElse: () => CategorySortOption.defaultOrder,
    );

ColorPreset colorPresetFromEntity(ColorPresetEntity e) {
  return ColorPreset(
    id: e.id,
    name: e.name,
    lightPrimary: Color(e.lightPrimary),
    lightSecondary: Color(e.lightSecondary),
    darkPrimary: Color(e.darkPrimary),
    darkSecondary: Color(e.darkSecondary),
    createdAt: DateTime.parse(e.createdAtIso),
  );
}
