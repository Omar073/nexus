import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';

class RemindersSelectionState {
  bool selectionMode = false;
  final Set<String> selectedIds = <String>{};

  void enter(String id) {
    selectionMode = true;
    selectedIds.add(id);
  }

  void toggle(String id) {
    if (selectedIds.remove(id)) {
      if (selectedIds.isEmpty) selectionMode = false;
      return;
    }
    selectionMode = true;
    selectedIds.add(id);
  }

  void clear() {
    selectionMode = false;
    selectedIds.clear();
  }

  void selectAll(Iterable<ReminderEntity> reminders) {
    selectionMode = true;
    selectedIds
      ..clear()
      ..addAll(reminders.map((r) => r.id));
  }
}
