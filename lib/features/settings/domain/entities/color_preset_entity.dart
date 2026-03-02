/// Domain entity for a saved color preset (pure Dart, no Flutter).
class ColorPresetEntity {
  const ColorPresetEntity({
    required this.id,
    required this.name,
    required this.lightPrimary,
    required this.lightSecondary,
    required this.darkPrimary,
    required this.darkSecondary,
    required this.createdAtIso,
  });

  final String id;
  final String name;
  final int lightPrimary;
  final int lightSecondary;
  final int darkPrimary;
  final int darkSecondary;
  final String createdAtIso;
}
