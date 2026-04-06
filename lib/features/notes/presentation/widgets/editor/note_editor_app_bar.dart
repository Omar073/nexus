import 'package:flutter/material.dart';
import 'package:nexus/features/notes/domain/entities/note_attachment_entity.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/category_selector.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/markdown/markdown_editor_area.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/attachment_button.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/note_editor_overflow_menu.dart';

/// Title field, mode actions, and overflow for the editor.
class NoteEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NoteEditorAppBar({
    super.key,
    required this.note,
    required this.titleController,
    required this.isMarkdown,
    required this.markdownLayout,
    required this.showVoiceNotes,
    required this.showCategoryPicker,
    required this.onToggleMarkdown,
    required this.onLayoutChanged,
    required this.onToggleVoiceNotes,
    required this.onToggleCategoryPicker,
    required this.onFindInNote,
    required this.onDeleteNote,
    this.onAttachmentAdded,
  });

  final NoteEntity note;
  final TextEditingController titleController;
  final bool isMarkdown;
  final MarkdownLayout markdownLayout;
  final bool showVoiceNotes;
  final bool showCategoryPicker;
  final ValueChanged<bool> onToggleMarkdown;
  final ValueChanged<MarkdownLayout> onLayoutChanged;
  final ValueChanged<bool> onToggleVoiceNotes;
  final VoidCallback onToggleCategoryPicker;
  final VoidCallback onFindInNote;
  final VoidCallback onDeleteNote;
  final ValueChanged<NoteAttachmentEntity>? onAttachmentAdded;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? Colors.black : theme.colorScheme.surface,
      foregroundColor: isDark ? Colors.white : theme.colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            maxLines: 1,
            onTap: onToggleCategoryPicker,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Untitled',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.8,
                ),
                fontWeight: FontWeight.w600,
              ),
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
          if (showCategoryPicker)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: DefaultTextStyle(
                style:
                    theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12),
                child: CategorySelector(note: note),
              ),
            ),
        ],
      ),
      actions: [
        AttachmentButton(note: note, onAttachmentAdded: onAttachmentAdded),
        NoteEditorOverflowMenu(
          isMarkdown: isMarkdown,
          markdownLayout: markdownLayout,
          showVoiceNotes: showVoiceNotes,
          onFindInNote: onFindInNote,
          onToggleMarkdown: onToggleMarkdown,
          onLayoutChanged: onLayoutChanged,
          onToggleVoiceNotes: onToggleVoiceNotes,
          onDeleteNote: onDeleteNote,
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
