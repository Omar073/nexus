/// Sort options for categories.
enum CategorySortOption {
  /// Default insertion order
  defaultOrder,

  /// Alphabetical (A-Z)
  alphabeticalAsc,

  /// Alphabetical (Z-A)
  alphabeticalDesc,

  /// Recently modified (Based on latest task update)
  recentlyModified,
}

extension CategorySortOptionExtension on CategorySortOption {
  String get displayName => switch (this) {
    CategorySortOption.defaultOrder => 'Default',
    CategorySortOption.alphabeticalAsc => 'Alphabetical (A-Z)',
    CategorySortOption.alphabeticalDesc => 'Alphabetical (Z-A)',
    CategorySortOption.recentlyModified => 'Recently Modified',
  };

  String get description => switch (this) {
    CategorySortOption.defaultOrder => 'Custom order',
    CategorySortOption.alphabeticalAsc => 'Sort by name A-Z',
    CategorySortOption.alphabeticalDesc => 'Sort by name Z-A',
    CategorySortOption.recentlyModified => 'Sort by latest activity',
  };
}
