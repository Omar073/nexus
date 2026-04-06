import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/markdown/markdown_editor_area.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/markdown/note_rich_toolbar.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/voice/voice_notes_section.dart';

/// Chooses Quill vs markdown editor and applies RTL when needed.

class NoteEditorBody extends StatelessWidget {
  const NoteEditorBody({
    super.key,
    required this.note,
    required this.isMarkdown,
    required this.markdownLayout,
    required this.showVoiceNotes,
    required this.toolbarAtTop,
    required this.onToolbarPositionChanged,
    required this.quillController,
    required this.markdownController,
  });

  final NoteEntity note;
  final bool isMarkdown;
  final MarkdownLayout markdownLayout;
  final bool showVoiceNotes;
  final bool toolbarAtTop;
  final ValueChanged<bool> onToolbarPositionChanged;
  final quill.QuillController quillController;
  final TextEditingController markdownController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isMarkdown && toolbarAtTop)
          _DraggableToolbar(
            controller: quillController,
            onMoveToBottom: () => onToolbarPositionChanged(false),
          ),
        if (!isMarkdown && toolbarAtTop) const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isMarkdown
                ? MarkdownEditorArea(
                    controller: markdownController,
                    layout: markdownLayout,
                  )
                : Directionality(
                    textDirection:
                        _looksArabic(quillController.document.toPlainText())
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: quill.QuillEditor.basic(
                      controller: quillController,
                      config: const quill.QuillEditorConfig(),
                    ),
                  ),
          ),
        ),
        if (!isMarkdown && !toolbarAtTop) const SizedBox(height: 8),
        if (!isMarkdown && !toolbarAtTop)
          _DraggableToolbar(
            controller: quillController,
            onMoveToTop: () => onToolbarPositionChanged(true),
          ),
        if (showVoiceNotes) VoiceNotesSection(note: note),
      ],
    );
  }

  static bool _looksArabic(String s) {
    for (final code in s.runes) {
      final isArabic =
          (code >= 0x0600 && code <= 0x06FF) ||
          (code >= 0x0750 && code <= 0x077F) ||
          (code >= 0x08A0 && code <= 0x08FF) ||
          (code >= 0xFB50 && code <= 0xFDFF) ||
          (code >= 0xFE70 && code <= 0xFEFF);
      if (isArabic) return true;
    }
    return false;
  }
}

class _DraggableToolbar extends StatelessWidget {
  const _DraggableToolbar({
    required this.controller,
    this.onMoveToTop,
    this.onMoveToBottom,
  });

  final quill.QuillController controller;
  final VoidCallback? onMoveToTop;
  final VoidCallback? onMoveToBottom;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v > 0 && onMoveToBottom != null) {
          onMoveToBottom!();
        } else if (v < 0 && onMoveToTop != null) {
          onMoveToTop!();
        }
      },
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          NoteRichToolbar(controller: controller),
        ],
      ),
    );
  }
}
