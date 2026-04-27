import 'package:nexus/features/tasks/domain/entities/task_entity.dart';

class CategorySectionTaskBuckets {
  CategorySectionTaskBuckets({
    required this.rootTasks,
    required this.bySubcategory,
  });

  final List<TaskEntity> rootTasks;
  final Map<String, List<TaskEntity>> bySubcategory;
}

CategorySectionTaskBuckets bucketTasksBySubcategory(List<TaskEntity> tasks) {
  final rootTasks = <TaskEntity>[];
  final subcategoryTasks = <String, List<TaskEntity>>{};

  for (final task in tasks) {
    if (task.subcategoryId == null) {
      rootTasks.add(task);
    } else {
      subcategoryTasks.putIfAbsent(task.subcategoryId!, () => []).add(task);
    }
  }
  return CategorySectionTaskBuckets(
    rootTasks: rootTasks,
    bySubcategory: subcategoryTasks,
  );
}

List<String> sortSubcategoryIdsByName({
  required Iterable<String> subcategoryIds,
  required String Function(String id) resolveName,
}) {
  final sorted = subcategoryIds.toList();
  sorted.sort((a, b) => resolveName(a).compareTo(resolveName(b)));
  return sorted;
}
