import 'package:flutter/material.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/attachment_button.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/voice/voice_recorder_button.dart';

/// App bar for the note editor with title field, actions, and save button.
class NoteEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NoteEditorAppBar({
    super.key,
    required this.note,
    required this.titleController,
    required this.onSave,
  });

  final NoteEntity note;
  final TextEditingController titleController;
  final VoidCallback onSave;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: TextField(
        controller: titleController,
        maxLines: 1,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Untitled',
          hintStyle: TextStyle(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          isCollapsed: true,
        ),
      ),
      actions: [
        VoiceRecorderButton(note: note),
        AttachmentButton(note: note),
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Save'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
