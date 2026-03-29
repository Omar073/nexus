import 'package:flutter/material.dart';
import 'package:nexus/features/notes/domain/entities/note_attachment_entity.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/attachment_button.dart';

/// Title field, mode actions, and overflow for the editor.
class NoteEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NoteEditorAppBar({
    super.key,
    required this.note,
    required this.titleController,
    this.onAttachmentAdded,
  });

  final NoteEntity note;
  final TextEditingController titleController;
  final ValueChanged<NoteAttachmentEntity>? onAttachmentAdded;

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
        AttachmentButton(note: note, onAttachmentAdded: onAttachmentAdded),
        const SizedBox(width: 8),
      ],
    );
  }
}
