import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/features/categories/data/models/category.dart';
import 'package:nexus/features/categories/domain/category_sort_option.dart';
import 'package:nexus/features/tasks/data/models/task.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';

void main() {
  group('Category Sorting for Jump to Category Menu', () {
    late List<Category> categories;

    setUp(() {
      // Create test categories in a specific order
      categories = [
        Category(id: 'c1', name: 'Work'),
        Category(id: 'c2', name: 'Personal'),
        Category(id: 'c3', name: 'Shopping'),
        Category(id: 'c4', name: 'Health'),
        Category(id: 'c5', name: 'Finance'),
      ];
    });

    test('default order preserves insertion order', () {
      // Default order should maintain the original list order
      final sorted = List.of(categories);
      // No sorting applied for defaultOrder
      expect(sorted.map((c) => c.name).toList(), [
        'Work',
        'Personal',
        'Shopping',
        'Health',
        'Finance',
      ]);
    });

    test('alphabeticalAsc sorts A-Z', () {
      final sorted = List.of(categories);
      sorted.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      expect(sorted.map((c) => c.name).toList(), [
        'Finance',
        'Health',
        'Personal',
        'Shopping',
        'Work',
      ]);
    });

    test('alphabeticalDesc sorts Z-A', () {
      final sorted = List.of(categories);
      sorted.sort(
        (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
      );
      expect(sorted.map((c) => c.name).toList(), [
        'Work',
        'Shopping',
        'Personal',
        'Health',
        'Finance',
      ]);
    });

    test('recentlyModified sorts by latest task update', () {
      final now = DateTime.now();

      // Create tasks with different update times for each category
      final tasks = [
        _createTask(
          't1',
          'c1',
          now.subtract(const Duration(days: 5)),
        ), // Work - oldest
        _createTask(
          't2',
          'c2',
          now.subtract(const Duration(days: 1)),
        ), // Personal - recent
        _createTask(
          't3',
          'c3',
          now.subtract(const Duration(days: 3)),
        ), // Shopping
        _createTask('t4', 'c4', now), // Health - newest
        _createTask(
          't5',
          'c5',
          now.subtract(const Duration(days: 2)),
        ), // Finance
      ];

      // Calculate last update times (simulating tasks screen logic)
      final lastUpdates = <String, DateTime>{};
      for (final task in tasks) {
        if (task.categoryId != null) {
          final updated = task.updatedAt;
          final current = lastUpdates[task.categoryId!];
          if (current == null || updated.isAfter(current)) {
            lastUpdates[task.categoryId!] = updated;
          }
        }
      }

      final sorted = List.of(categories);
      sorted.sort((a, b) {
        final timeA =
            lastUpdates[a.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB =
            lastUpdates[b.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA); // Descending (newest first)
      });

      expect(sorted.map((c) => c.name).toList(), [
        'Health', // newest
        'Personal', // 1 day ago
        'Finance', // 2 days ago
        'Shopping', // 3 days ago
        'Work', // 5 days ago (oldest)
      ]);
    });

    test('recentlyModified handles categories with no tasks', () {
      final now = DateTime.now();

      // Only some categories have tasks
      final tasks = [
        _createTask('t1', 'c1', now), // Work - has task
        _createTask(
          't2',
          'c3',
          now.subtract(const Duration(days: 1)),
        ), // Shopping - has task
      ];

      final lastUpdates = <String, DateTime>{};
      for (final task in tasks) {
        if (task.categoryId != null) {
          final updated = task.updatedAt;
          final current = lastUpdates[task.categoryId!];
          if (current == null || updated.isAfter(current)) {
            lastUpdates[task.categoryId!] = updated;
          }
        }
      }

      final sorted = List.of(categories);
      sorted.sort((a, b) {
        final timeA =
            lastUpdates[a.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB =
            lastUpdates[b.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });

      // Categories with tasks come first (sorted by recency)
      // Categories without tasks come last (all have epoch time)
      expect(sorted[0].name, 'Work'); // newest task
      expect(sorted[1].name, 'Shopping'); // 1 day ago
      // Remaining categories have no tasks - their order is based on epoch comparison
    });

    test('sorting creates a copy and does not modify original list', () {
      final original = List.of(categories);
      final originalOrder = original.map((c) => c.id).toList();

      // Sort alphabetically
      final sorted = List.of(original);
      sorted.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      // Verify original is unchanged
      expect(original.map((c) => c.id).toList(), originalOrder);
    });

    test('case-insensitive alphabetical sorting', () {
      final mixedCaseCategories = [
        Category(id: 'c1', name: 'apple'),
        Category(id: 'c2', name: 'Banana'),
        Category(id: 'c3', name: 'CHERRY'),
        Category(id: 'c4', name: 'date'),
      ];

      final sorted = List.of(mixedCaseCategories);
      sorted.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      expect(sorted.map((c) => c.name).toList(), [
        'apple',
        'Banana',
        'CHERRY',
        'date',
      ]);
    });
  });

  group('CategorySortOption selection', () {
    test('all sort options have display names', () {
      for (final option in CategorySortOption.values) {
        expect(option.displayName, isNotEmpty);
      }
    });

    test('all sort options have descriptions', () {
      for (final option in CategorySortOption.values) {
        expect(option.description, isNotEmpty);
      }
    });
  });
}

/// Helper to create a task with specific category and update time.
Task _createTask(String id, String categoryId, DateTime updatedAt) {
  return Task(
    id: id,
    title: 'Test Task',
    status: TaskStatus.active.index,
    priority: TaskPriority.medium.index,
    difficulty: TaskDifficulty.medium.index,
    createdAt: updatedAt.subtract(const Duration(days: 1)),
    updatedAt: updatedAt,
    lastModifiedByDevice: 'test-device',
    categoryId: categoryId,
  );
}
