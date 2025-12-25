import 'package:flutter/material.dart';
import 'package:nexus/features/notes/controllers/note_controller.dart';
import 'package:nexus/features/notes/views/note_editor_screen.dart';
import 'package:nexus/features/notes/views/widgets/note_tile.dart';
import 'package:provider/provider.dart';

class NotesListScreen extends StatelessWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NoteController>();
    final notes = controller.visibleNotes;

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search notes',
                border: OutlineInputBorder(),
              ),
              onChanged: controller.setQuery,
            ),
          ),
          Expanded(
            child: notes.isEmpty
                ? const Center(child: Text('No notes'))
                : ListView.separated(
                    itemCount: notes.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        NoteTile(note: notes[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes_fab',
        onPressed: () async {
          final note = await controller.createEmpty();
          if (!context.mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NoteEditorScreen(noteId: note.id),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
