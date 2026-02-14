import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/hive/hive_type_ids.dart';
import 'package:nexus/features/tasks/controllers/category_controller.dart';
import 'package:nexus/features/tasks/models/category.dart';

/// Integration test: Category + Task controller interaction.
void main() {
  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(HiveTypeIds.category)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    await Hive.openBox<Category>(HiveBoxes.categories);
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('Category cascade', () {
    test('deleteCategory with onClearTasks callback', () async {
      final controller = CategoryController();
      final parent = await controller.createCategory('DeleteMe');
      await controller.createCategory('Child', parentId: parent.id);

      final clearedIds = <String>[];
      await controller.deleteCategory(
        parent.id,
        onClearTasks: (ids) async => clearedIds.addAll(ids),
      );

      // Should have cleared both parent and child
      expect(clearedIds, hasLength(2));
      expect(controller.getById(parent.id), isNull);
      controller.dispose();
    });

    test('subcategories returned correctly', () async {
      final controller = CategoryController();
      final parent = await controller.createCategory('Parent');
      final child1 = await controller.createCategory(
        'Child 1',
        parentId: parent.id,
      );
      final child2 = await controller.createCategory(
        'Child 2',
        parentId: parent.id,
      );

      final subs = controller.getSubcategories(parent.id);

      expect(subs, hasLength(2));
      expect(subs.map((c) => c.id), containsAll([child1.id, child2.id]));
      controller.dispose();
    });
  });
}
