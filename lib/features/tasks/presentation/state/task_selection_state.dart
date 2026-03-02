import 'package:nexus/features/tasks/domain/entities/task_entity.dart';

/// Holds selection state and logic for multi-select mode on the tasks screen.
/// The owning widget should call [notify] after mutations to trigger rebuilds.
class TaskSelectionState {
  bool selectionMode = false;
  final Set<String> selectedIds = {};

  void enter(String taskId) {
    selectionMode = true;
    selectedIds
      ..clear()
      ..add(taskId);
  }

  void toggle(String taskId) {
    if (selectedIds.remove(taskId)) {
      if (selectedIds.isEmpty) {
        selectionMode = false;
      }
    } else {
      selectionMode = true;
      selectedIds.add(taskId);
    }
  }

  void clear() {
    selectionMode = false;
    selectedIds.clear();
  }

  void selectAll(Iterable<TaskEntity> tasks) {
    selectionMode = true;
    selectedIds
      ..clear()
      ..addAll(tasks.map((t) => t.id));
  }
}
