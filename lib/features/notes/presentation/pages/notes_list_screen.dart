import 'package:flutter/material.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/presentation/logic/notes_bulk_actions_logic.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/notes/presentation/state/notes_selection_state.dart';
import 'package:nexus/features/notes/presentation/pages/note_editor_screen.dart';
import 'package:nexus/features/notes/presentation/widgets/list/notes_body.dart';
import 'package:nexus/features/notes/presentation/widgets/list/notes_selection_bar.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:provider/provider.dart';

/// Notes list screen following Nexus design system.
/// Features large header, search bar, filter chips, and styled note cards.
class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final _searchController = TextEditingController();
  final NotesSelectionState _selectionState = NotesSelectionState();

  void _enterSelection(String id) {
    setState(() {
      _selectionState.enter(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      _selectionState.toggle(id);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionState.clear();
    });
  }

  void _selectAllNotes(Iterable<NoteEntity> notes) {
    setState(() {
      _selectionState.selectAll(notes);
    });
  }

  Future<void> _deleteSelected(NoteController controller) async {
    final ids = _selectionState.selectedIds.toList();
    final notes = ids
        .map((id) => controller.byId(id))
        .whereType<NoteEntity>()
        .toList();
    _clearSelection();
    await deleteNotesWithUndo(
      context: context,
      controller: controller,
      notes: notes,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NoteController>();
    final categoryController = context.watch<CategoryController>();
    final navBarStyle = context.watch<SettingsController>().navBarStyle;

    final notes = controller.visibleNotes;
    final categories = categoryController.rootCategories;
    final filterLabels = ['All notes', ...categories.map((c) => c.name)];

    int selectedFilterIndex = 0;
    if (controller.categoryIdFilter != null) {
      final index = categories.indexWhere(
        (c) => c.id == controller.categoryIdFilter,
      );
      if (index != -1) selectedFilterIndex = index + 1;
    }

    return Scaffold(
      body: SafeArea(
        child: NotesBody(
          notes: notes,
          categories: categories,
          filterLabels: filterLabels,
          selectedFilterIndex: selectedFilterIndex,
          onFilterSelected: (index) {
            if (index == 0) {
              controller.setCategoryFilter(null);
            } else {
              final category = categories[index - 1];
              controller.setCategoryFilter(category.id);
            }
          },
          selectionMode: _selectionState.selectionMode,
          selectedNoteIds: _selectionState.selectedIds,
          onEnterSelection: _enterSelection,
          onToggleSelection: _toggleSelection,
          navBarStyle: navBarStyle,
          searchController: _searchController,
        ),
      ),
      floatingActionButton: _selectionState.selectionMode
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: navBarStyle.fabOffset(context)),
              child: FloatingActionButton(
                heroTag: 'notes_fab',
                onPressed: () async {
                  final note = await controller.createEmpty();
                  if (!context.mounted) return;
                  await NoteEditorScreen.push(context, note.id);
                },
                child: const Icon(Icons.add),
              ),
            ),
      bottomNavigationBar: _selectionState.selectionMode
          ? NotesSelectionBar(
              selectedCount: _selectionState.selectedIds.length,
              onSelectAll: () => _selectAllNotes(notes),
              onExitSelection: _clearSelection,
              onDelete: () => _deleteSelected(controller),
            )
          : null,
    );
  }
}
