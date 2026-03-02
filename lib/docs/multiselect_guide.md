## Multi‑select and bulk deletion (Tasks, Reminders, Notes)

This doc explains how multi‑selection and bulk deletion are implemented for:

- **Tasks**
- **Reminders**
- **Notes**

The pattern is the same across features:

- **Long‑press** an item to enter selection mode.
- While selection mode is active:
  - Tapping an item toggles its selected state.
  - A **bottom action bar** shows the number of selected items and bulk actions.
  - The bar includes **Select all** and **Exit selection** actions.
- Exiting selection mode (via the bar or by deselecting everything) clears all selections.

---

## 1. Common state pattern (per screen)

Each screen (`TasksScreen`, `RemindersScreen`, `NotesListScreen`) owns:

- `bool _selectionMode` – whether we are in selection mode.
- `Set<String> _selected...Ids` – ids of currently selected items.

- Helper methods:
  - `_enterSelection(String id)` – start selection with a given id.
  - `_toggleSelection(String id)` – add/remove a given id.
  - `_clearSelection()` – exit selection mode and clear the set.

### 1.1 Example: notes selection state

```dart
class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedNoteIds = <String>{};

  void _enterSelection(String id) {
    setState(() {
      _selectionMode = true;
      _selectedNoteIds
        ..clear()
        ..add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedNoteIds.remove(id)) {
        if (_selectedNoteIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectionMode = true;
        _selectedNoteIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedNoteIds.clear();
    });
  }
}
```

The tasks and reminders screens follow the same pattern with `_selectedTaskIds` and `_selectedReminderIds`.

---

## 2. Tile widgets: selection props and gestures

Each tile widget (task, reminder, note) was extended with a small, consistent API:

- `bool selectionMode` – if true, tap toggles selection instead of opening the editor.
- `bool isSelected` – whether this tile is currently selected.
- `VoidCallback? onSelectionToggle` – called when the user taps in selection mode.
- `VoidCallback? onLongPress` – called to enter selection mode starting from this item.

Parent widgets (the screens and list bodies) pass these values down, so the tile is responsible only for **gestures and visuals**, not for managing the selected set.

### 2.1 Example: `NoteTile`

```dart
class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
    this.onLongPress,
  });

  final Note note;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: selectionMode
          ? onSelectionToggle
          : () {
              // existing behavior: open note editor
            },
      child: NexusCard(
        // ...
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // existing trailing widgets (timestamp, menu, etc.)
            if (isSelected)
              const Icon(
                Icons.check_circle,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
```

### 2.2 Example: `ReminderTile`

```dart
class ReminderTile extends StatelessWidget {
  const ReminderTile({
    super.key,
    required this.reminder,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
    this.onLongPress,
    // other callbacks...
  });

  final Reminder reminder;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: selectionMode ? onSelectionToggle : () {
        // existing tap behavior (e.g. open editor)
      },
      child: NexusCard(
        leftBorderColor: isSelected ? theme.colorScheme.primary : null,
        // ... main content ...
      ),
    );
  }
}
```

### 2.3 Example: task list item wrapper

Tasks are nested in grouped lists by category and subcategory. The wrapper around each `TaskItem` handles gestures and selection:

```dart
class CategorySectionTaskItem extends StatelessWidget {
  const CategorySectionTaskItem({
    super.key,
    required this.task,
    required this.onTap,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
    this.onLongPress,
  });

  final TaskEntity task;
  final VoidCallback onTap;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: selectionMode ? onSelectionToggle : onTap,
      child: TaskItem(
        task: task,
        isSelected: isSelected,
        // other callbacks (toggle complete, delete, etc.)
      ),
    );
  }
}
```

`TaskItem` and its content widgets use `isSelected` to adjust visual styling (e.g., border or background tint).

---

## 3. Task multi‑select: delete, toggle, move category

### 3.1 Screen‑level state and bulk helpers

`TasksScreen` owns the selection state and defines bulk operations:

```dart
class _TasksScreenState extends State<TasksScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedTaskIds = <String>{};

  void _enterTaskSelection(String id) {
    setState(() {
      _selectionMode = true;
      _selectedTaskIds
        ..clear()
        ..add(id);
    });
  }

  void _toggleTaskSelection(String id) {
    setState(() {
      if (_selectedTaskIds.contains(id)) {
        _selectedTaskIds.remove(id);
        if (_selectedTaskIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectionMode = true;
        _selectedTaskIds.add(id);
      }
    });
  }

  void _clearTaskSelection() {
    setState(() {
      _selectionMode = false;
      _selectedTaskIds.clear();
    });
  }

  Future<void> _deleteSelectedTasks(BuildContext context) async {
    final controller = context.read<TaskController>();
    final ids = _selectedTaskIds.toList();

    for (final id in ids) {
      await controller.deleteTask(id);
    }

    _clearTaskSelection();
  }

  // _toggleCompletedForSelected, _moveSelectedTasksToCategory(...) follow a similar pattern.
}
```

### 3.2 Bottom selection bar for tasks

The bottom bar (`TaskSelectionBar`) exposes the three task actions:

- **Toggle complete** – mark all selected tasks as complete or incomplete.
- **Move to category** – open category picker and bulk‑move tasks.
- **Delete** – call `deleteTask` for each selected id.

Usage:

```dart
return Scaffold(
  body: TasksTabBody(
    selectionMode: _selectionMode,
    selectedTaskIds: _selectedTaskIds,
    onTaskLongPress: _enterTaskSelection,
    onTaskSelectionToggle: _toggleTaskSelection,
    // ...
  ),
  bottomNavigationBar: TaskSelectionBar(
    visible: _selectionMode,
    selectedCount: _selectedTaskIds.length,
    onClearSelection: _clearTaskSelection,
    onToggleCompleted: () => _toggleCompletedForSelected(context),
    onMoveCategory: () => _moveSelectedTasksToCategory(context),
    onDelete: () => _deleteSelectedTasks(context),
  ),
);
```

---

## 4. Reminder multi‑select: delete, toggle, snooze

### 4.1 Screen‑level state and helpers

`RemindersScreen` mirrors the same pattern:

```dart
class _RemindersScreenState extends State<RemindersScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedReminderIds = <String>{};

  void _enterSelection(String id) {
    setState(() {
      _selectionMode = true;
      _selectedReminderIds
        ..clear()
        ..add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedReminderIds.remove(id)) {
        if (_selectedReminderIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectionMode = true;
        _selectedReminderIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedReminderIds.clear();
    });
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final controller = context.read<ReminderController>();
    final ids = _selectedReminderIds.toList();

    for (final id in ids) {
      await controller.deleteReminder(id);
    }

    _clearSelection();
  }

  // _toggleCompletedForSelected, _snoozeSelected(...) do the corresponding bulk actions.
}
```

### 4.2 Bottom selection bar for reminders

`ReminderSelectionBar` provides:

- **Toggle complete** – bulk complete/uncomplete reminders.
- **Snooze** – bulk snooze all selected reminders using the existing snooze flow.
- **Delete** – bulk delete using `ReminderController`.

The bar is shown only when `_selectionMode` is `true`.

---

## 5. Note multi‑select: bulk delete

### 5.1 Screen‑level delete

For notes, the only bulk action is **delete**, so `NotesListScreen` implements:

```dart
Future<void> _deleteSelected(BuildContext context) async {
  final controller = context.read<NoteController>();
  final ids = _selectedNoteIds.toList();

  for (final id in ids) {
    await controller.delete(id);
  }

  _clearSelection();
}
```

And passes that into a `NotesSelectionBar` that appears at the bottom when any notes are selected.

### 5.2 User experience summary

- **Tasks**
  - Long‑press any task to enter selection mode.
  - Tap additional tasks to select/deselect.
  - Use bottom bar to:
    - Toggle completion.
    - Move to another category.
    - Delete selected tasks.
- **Reminders**
  - Long‑press a reminder row to enter selection mode.
  - Tap more reminders to modify the selection.
  - Bottom bar actions:
    - Toggle completion.
    - Snooze selected reminders.
    - Delete selected reminders.
- **Notes**
  - Long‑press a note tile to enter selection mode.
  - Tap other notes to select/deselect.
  - Bottom bar:
    - Delete selected notes.

This structure keeps the deletion and multi‑selection behavior **consistent** across features while letting each screen expose exactly the actions you described.