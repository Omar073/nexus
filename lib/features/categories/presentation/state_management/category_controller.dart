import 'package:flutter/foundation.dart' hide Category;
import 'package:hive/hive.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/features/categories/data/models/category.dart';
import 'package:nexus/features/categories/domain/category_sort_option.dart';
import 'package:nexus/features/categories/domain/category_sortable_item.dart';
import 'package:uuid/uuid.dart';

/// Controller for managing task categories.
class CategoryController extends ChangeNotifier {
  CategoryController() {
    _box = Hive.box<Category>(HiveBoxes.categories);
    _seedDefaultCategories();
  }

  late final Box<Category> _box;
  static const _uuid = Uuid();

  /// Default categories to seed on first run.
  static const _defaultCategories = ['Work', 'College', 'Personal', 'Fun'];

  void _seedDefaultCategories() {
    if (_box.isEmpty) {
      for (final name in _defaultCategories) {
        final category = Category(id: _uuid.v4(), name: name);
        _box.put(category.id, category);
      }
      notifyListeners();
    }
  }

  /// Get all root categories (no parent).
  List<Category> get rootCategories =>
      _box.values.where((c) => c.parentId == null).toList();

  /// Get all categories including sub-categories.
  List<Category> get allCategories => _box.values.toList();

  /// Get sub-categories for a parent.
  List<Category> getSubcategories(String parentId) =>
      _box.values.where((c) => c.parentId == parentId).toList();

  /// Get category by ID.
  Category? getById(String id) => _box.get(id);

  /// Get sorted root categories based on sort option.
  /// For [CategorySortOption.recentlyModified], requires [sortableItems] (e.g. tasks).
  List<Category> getSortedCategories({
    required CategorySortOption sortOption,
    List<CategorySortableItem> sortableItems = const [],
  }) {
    final categories = List<Category>.from(rootCategories);

    switch (sortOption) {
      case CategorySortOption.defaultOrder:
        return categories; // Insertion order
      case CategorySortOption.alphabeticalAsc:
        categories.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case CategorySortOption.alphabeticalDesc:
        categories.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
      case CategorySortOption.recentlyModified:
        final lastUpdates = <String, DateTime>{};
        for (final item in sortableItems) {
          if (item.categoryId != null) {
            final current = lastUpdates[item.categoryId!];
            if (current == null || item.updatedAt.isAfter(current)) {
              lastUpdates[item.categoryId!] = item.updatedAt;
            }
          }
        }
        categories.sort((a, b) {
          final timeA =
              lastUpdates[a.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
          final timeB =
              lastUpdates[b.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
          return timeB.compareTo(timeA); // Descending (newest first)
        });
    }
    return categories;
  }

  /// Create a new category.
  Future<Category> createCategory(String name, {String? parentId}) async {
    final category = Category(
      id: _uuid.v4(),
      name: name.trim(),
      parentId: parentId,
    );
    await _box.put(category.id, category);
    notifyListeners();
    return category;
  }

  /// Update category name.
  Future<void> updateCategory(Category category, String name) async {
    category.name = name.trim();
    await category.save();
    notifyListeners();
  }

  /// Delete a category and its sub-categories.
  /// Optionally accepts [onClearTasks] to clear categoryId on tasks.
  Future<void> deleteCategory(
    String id, {
    Future<void> Function(List<String> categoryIds)? onClearTasks,
  }) async {
    final idsToDelete = <String>[id];
    final subs = getSubcategories(id);
    for (final sub in subs) {
      idsToDelete.add(sub.id);
    }

    if (onClearTasks != null) {
      await onClearTasks(idsToDelete);
    }

    for (final sub in subs) {
      await _box.delete(sub.id);
    }
    await _box.delete(id);
    notifyListeners();
  }

  /// Restore previously deleted categories (e.g. for undo).
  /// Pass the category and any subcategories that were deleted together.
  Future<void> restoreCategories(List<Category> categories) async {
    for (final c in categories) {
      await _box.put(
        c.id,
        Category(id: c.id, name: c.name, parentId: c.parentId),
      );
    }
    notifyListeners();
  }
}
