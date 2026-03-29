import 'package:flutter/material.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/note_editor_view.dart';
import 'package:provider/provider.dart';

/// Loads a note by id and hosts [NoteEditorView].
class NoteEditorScreen extends StatelessWidget {
  const NoteEditorScreen({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NoteController>();
    final note = notes.byId(noteId);

    if (note == null) {
      return const Scaffold(body: Center(child: Text('Note not found')));
    }

    return NoteEditorView(note: note);
  }
}
