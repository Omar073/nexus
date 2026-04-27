import 'package:nexus/features/notes/domain/entities/note_entity.dart';

class NotesSelectionState {
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

  void selectAll(Iterable<NoteEntity> notes) {
    selectionMode = true;
    selectedIds
      ..clear()
      ..addAll(notes.map((n) => n.id));
  }
}
