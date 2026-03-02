import 'package:nexus/features/settings/domain/entities/color_preset_entity.dart';

/// Domain entity for app settings (pure Dart, no Flutter).
/// Values use primitives so domain stays dependency-free.
class AppSettingsEntity {
  const AppSettingsEntity({
    required this.themeMode,
    required this.completedRetentionDays,
    required this.autoDeleteCompletedTasks,
    required this.navBarStyle,
    required this.darkPalette,
    required this.taskSortOption,
    required this.categorySortOption,
    this.lightPrimary,
    this.lightSecondary,
    this.darkPrimary,
    this.darkSecondary,
    this.presets = const [],
  });

  final String themeMode;
  final int completedRetentionDays;
  final bool autoDeleteCompletedTasks;
  final String navBarStyle;
  final String darkPalette;
  final String taskSortOption;
  final String categorySortOption;
  final int? lightPrimary;
  final int? lightSecondary;
  final int? darkPrimary;
  final int? darkSecondary;
  final List<ColorPresetEntity> presets;
}
