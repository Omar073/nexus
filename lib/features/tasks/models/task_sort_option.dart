/// Sort options for tasks within categories.
enum TaskSortOption {
  /// Newest first (by createdAt desc)
  newestFirst,

  /// Oldest first (by createdAt asc)
  oldestFirst,

  /// Recently modified first (by updatedAt desc)
  recentlyModified,

  /// Due date soonest first (by dueDate asc)
  dueDateAsc,

  /// Priority high to low
  priorityDesc,
}

extension TaskSortOptionExtension on TaskSortOption {
  String get displayName => switch (this) {
    TaskSortOption.newestFirst => 'Newest First',
    TaskSortOption.oldestFirst => 'Oldest First',
    TaskSortOption.recentlyModified => 'Recently Modified',
    TaskSortOption.dueDateAsc => 'Due Date',
    TaskSortOption.priorityDesc => 'Priority',
  };

  String get description => switch (this) {
    TaskSortOption.newestFirst => 'Show newest tasks first',
    TaskSortOption.oldestFirst => 'Show oldest tasks first',
    TaskSortOption.recentlyModified => 'Show recently updated first',
    TaskSortOption.dueDateAsc => 'Show soonest due first',
    TaskSortOption.priorityDesc => 'Show high priority first',
  };
}
