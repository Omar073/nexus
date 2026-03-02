import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/features/categories/data/models/category.dart';
import 'package:nexus/features/categories/domain/category_sort_option.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/tasks/data/mappers/task_mapper.dart';
import 'package:nexus/features/tasks/data/models/task.dart';
import 'package:nexus/features/tasks/data/models/task_attachment.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.category)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.task)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.taskAttachment)) {
      Hive.registerAdapter(TaskAttachmentAdapter());
    }
    await Hive.openBox<Category>(HiveBoxes.categories);
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('CategoryController', () {
    test('seeds default categories on first run', () {
      final controller = CategoryController();

      expect(controller.rootCategories.length, 4);
      final names = controller.rootCategories.map((c) => c.name);
      expect(names, containsAll(['Work', 'College', 'Personal', 'Fun']));
      controller.dispose();
    });

    test('does not re-seed on subsequent creation', () {
      CategoryController().dispose();
      final controller = CategoryController();

      // Still 4, not 8
      expect(controller.rootCategories.length, 4);
      controller.dispose();
    });

    test('createCategory adds to list', () async {
      final controller = CategoryController();

      final created = await controller.createCategory('Errands');

      expect(created.name, 'Errands');
      expect(controller.rootCategories, contains(created));
      controller.dispose();
    });

    test('createCategory trims whitespace', () async {
      final controller = CategoryController();

      final created = await controller.createCategory('  Chores  ');

      expect(created.name, 'Chores');
      controller.dispose();
    });

    test('deleteCategory removes category and subcategories', () async {
      final controller = CategoryController();
      final parent = await controller.createCategory('Parent');
      await controller.createCategory('Child', parentId: parent.id);

      await controller.deleteCategory(parent.id);

      expect(controller.getById(parent.id), isNull);
      expect(controller.getSubcategories(parent.id), isEmpty);
      controller.dispose();
    });

    test('getSortedCategories returns alphabetical asc', () {
      final controller = CategoryController();

      final sorted = controller.getSortedCategories(
        sortOption: CategorySortOption.alphabeticalAsc,
      );

      // Names should be ascending
      for (var i = 0; i < sorted.length - 1; i++) {
        expect(
          sorted[i].name.toLowerCase().compareTo(
            sorted[i + 1].name.toLowerCase(),
          ),
          lessThanOrEqualTo(0),
        );
      }
      controller.dispose();
    });

    test('getSortedCategories by recentlyModified uses tasks', () {
      final controller = CategoryController();
      final cats = controller.rootCategories;
      final now = DateTime.now();

      final tasks = [
        Task(
          id: 't1',
          title: 'Recent',
          status: 0,
          createdAt: now,
          updatedAt: now,
          lastModifiedByDevice: 'dev',
          categoryId: cats.last.id,
        ),
        Task(
          id: 't2',
          title: 'Old',
          status: 0,
          createdAt: now.subtract(const Duration(days: 10)),
          updatedAt: now.subtract(const Duration(days: 10)),
          lastModifiedByDevice: 'dev',
          categoryId: cats.first.id,
        ),
      ];

      final sorted = controller.getSortedCategories(
        sortOption: CategorySortOption.recentlyModified,
        sortableItems: tasks.map(TaskMapper.toEntity).toList(),
      );

      // Category with most recent task should be first
      expect(sorted.first.id, cats.last.id);
      controller.dispose();
    });
  });
}
