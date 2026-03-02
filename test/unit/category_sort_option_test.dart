import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/categories/domain/category_sort_option.dart';

void main() {
  group('CategorySortOption', () {
    test('has correct display names', () {
      expect(CategorySortOption.defaultOrder.displayName, 'Default');
      expect(
        CategorySortOption.alphabeticalAsc.displayName,
        'Alphabetical (A-Z)',
      );
      expect(
        CategorySortOption.alphabeticalDesc.displayName,
        'Alphabetical (Z-A)',
      );
      expect(
        CategorySortOption.recentlyModified.displayName,
        'Recently Modified',
      );
    });

    test('has all expected values', () {
      expect(CategorySortOption.values.length, 4);
      expect(
        CategorySortOption.values,
        contains(CategorySortOption.defaultOrder),
      );
      expect(
        CategorySortOption.values,
        contains(CategorySortOption.alphabeticalAsc),
      );
      expect(
        CategorySortOption.values,
        contains(CategorySortOption.alphabeticalDesc),
      );
      expect(
        CategorySortOption.values,
        contains(CategorySortOption.recentlyModified),
      );
    });
  });
}
