import 'package:flutter/material.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/note_editor_view.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:provider/provider.dart';

/// Note editor screen. Loads the note by id and delegates to [NoteEditorView].
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

    final navBarStyle = context.watch<SettingsController>().navBarStyle;

    return NoteEditorView(note: note, navBarStyle: navBarStyle);
  }
}
