import 'package:flutter/material.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';

Future<void> deleteNotesWithUndo({
  required BuildContext context,
  required NoteController controller,
  required List<NoteEntity> notes,
}) async {
  for (final note in notes) {
    await controller.delete(note);
  }
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          for (final note in notes) {
            await controller.restoreNote(note);
          }
          messenger.hideCurrentSnackBar();
        },
        child: Row(
          children: [
            Expanded(
              child: Text(
                notes.length == 1
                    ? 'Note deleted'
                    : '${notes.length} notes deleted',
              ),
            ),
            Text(
              'Click to undo',
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
