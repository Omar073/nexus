import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:nexus/features/tasks/domain/task_sort_option.dart';
import 'package:nexus/features/tasks/presentation/extensions/task_entity_extensions.dart';

/// Helper class for sorting tasks.
class TaskSortingHelper {
  const TaskSortingHelper(this._settings);

  final SettingsController _settings;

  List<TaskEntity> applySorting(List<TaskEntity> filtered) {
    final now = DateTime.now();
    final urgentThreshold = now.add(const Duration(hours: 48));

    final urgent = <TaskEntity>[];
    final highPriority = <TaskEntity>[];
    final normal = <TaskEntity>[];

    for (final t in filtered) {
      final due = t.dueDate;
      final isUrgent =
          due != null && due.isBefore(urgentThreshold) && due.isAfter(now);
      final isHighPriority = t.priorityEnum == TaskPriority.high;

      if (isUrgent) {
        urgent.add(t);
      } else if (isHighPriority) {
        highPriority.add(t);
      } else {
        normal.add(t);
      }
    }

    urgent.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    _applySortOption(highPriority);
    _applySortOption(normal);

    return [...urgent, ...highPriority, ...normal];
  }

  void _applySortOption(List<TaskEntity> tasks) {
    final sortOption = _settings.taskSortOption;
    switch (sortOption) {
      case TaskSortOption.newestFirst:
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TaskSortOption.oldestFirst:
        tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case TaskSortOption.recentlyModified:
        tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case TaskSortOption.dueDateAsc:
        tasks.sort((a, b) {
          final ad = a.dueDate;
          final bd = b.dueDate;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
        });
      case TaskSortOption.priorityDesc:
        int priorityScore(TaskPriority? p) => switch (p) {
          TaskPriority.high => 3,
          TaskPriority.medium => 2,
          TaskPriority.low => 1,
          null => 0,
        };
        tasks.sort(
          (a, b) => priorityScore(
            b.priorityEnum,
          ).compareTo(priorityScore(a.priorityEnum)),
        );
    }
  }
}
