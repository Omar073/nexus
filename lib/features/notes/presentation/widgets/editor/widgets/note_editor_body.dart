import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nexus/core/services/note_embed_service.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/category_selector.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/markdown/markdown_editor_area.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/markdown/note_markdown_toggle_row.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/markdown/note_rich_toolbar.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/voice/voice_notes_section.dart';

/// Chooses Quill vs markdown editor and applies RTL when needed.

class NoteEditorBody extends StatelessWidget {
  const NoteEditorBody({
    super.key,
    required this.note,
    required this.isMarkdown,
    required this.markdownLayout,
    required this.onMarkdownChanged,
    required this.onLayoutChanged,
    required this.quillController,
    required this.markdownController,
    required this.embedService,
  });

  final NoteEntity note;
  final bool isMarkdown;
  final MarkdownLayout markdownLayout;
  final ValueChanged<bool> onMarkdownChanged;
  final ValueChanged<MarkdownLayout> onLayoutChanged;
  final quill.QuillController quillController;
  final TextEditingController markdownController;
  final NoteEmbedService embedService;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CategorySelector(note: note),
        NoteMarkdownToggleRow(
          isMarkdown: isMarkdown,
          layout: markdownLayout,
          onMarkdownChanged: onMarkdownChanged,
          onLayoutChanged: onLayoutChanged,
        ),
        if (!isMarkdown) NoteRichToolbar(controller: quillController),
        const SizedBox(height: 8),
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
        VoiceNotesSection(note: note, embedService: embedService),
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
