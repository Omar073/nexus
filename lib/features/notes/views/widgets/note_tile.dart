import 'package:flutter/material.dart';
import 'package:nexus/features/notes/controllers/note_controller.dart';
import 'package:nexus/features/notes/models/note.dart';
import 'package:nexus/features/notes/views/note_editor_screen.dart';
import 'package:nexus/features/notes/views/widgets/rtl_aware_text.dart';
import 'package:provider/provider.dart';

/// A list tile for displaying a note with delete action.
class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final title = note.title ?? 'Untitled';
    return ListTile(
      title: RtlAwareText(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        note.updatedAt.toString(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: 'Delete',
        icon: const Icon(Icons.delete_outline),
        onPressed: () => context.read<NoteController>().delete(note),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: note.id)),
      ),
    );
  }
}
