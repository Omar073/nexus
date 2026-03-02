/// Minimal contract for items that can be used to sort categories by recency.
/// Implemented by [TaskEntity] so categories can sort by "recently modified"
/// without depending on the tasks feature.
abstract class CategorySortableItem {
  String? get categoryId;
  DateTime get updatedAt;
}
