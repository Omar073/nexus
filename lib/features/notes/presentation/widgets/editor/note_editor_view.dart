import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nexus/core/services/note_embed_service.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/category_selector.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/markdown/markdown_editor_area.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/note_editor_app_bar.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/markdown/note_markdown_toggle_row.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/markdown/note_rich_toolbar.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/voice/voice_notes_section.dart';
import 'package:nexus/features/settings/data/models/nav_bar_style.dart';
import 'package:provider/provider.dart';

/// Main editor view with all state and logic for editing a note.
/// Hosted by [NoteEditorScreen] which handles loading and "not found".
class NoteEditorView extends StatefulWidget {
  const NoteEditorView({
    super.key,
    required this.note,
    required this.navBarStyle,
  });

  final NoteEntity note;
  final NavBarStyle navBarStyle;

  @override
  State<NoteEditorView> createState() => _NoteEditorViewState();
}

class _NoteEditorViewState extends State<NoteEditorView> {
  quill.QuillController? _controller;
  final _title = TextEditingController();
  final _embedService = NoteEmbedService();
  final _markdownController = TextEditingController();

  bool _titleInitialized = false;
  bool _markdownInitialized = false;
  bool _isMarkdown = false;
  MarkdownLayout _markdownLayout = MarkdownLayout.tabs;

  @override
  void dispose() {
    _controller?.dispose();
    _title.dispose();
    _markdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final notes = context.watch<NoteController>();

    _controller ??= _buildController(note);
    if (!_titleInitialized) {
      _title.text = note.title ?? '';
      _titleInitialized = true;
    }
    if (!_markdownInitialized) {
      _isMarkdown = note.isMarkdown;
      if (_isMarkdown && _controller != null) {
        _markdownController.text = _controller!.document.toPlainText();
      }
      _markdownInitialized = true;
    }

    return Scaffold(
      appBar: NoteEditorAppBar(
        note: note,
        titleController: _title,
        onSave: () => _save(notes),
      ),
      body: Column(
        children: [
          CategorySelector(note: note),
          NoteMarkdownToggleRow(
            isMarkdown: _isMarkdown,
            layout: _markdownLayout,
            onMarkdownChanged: _onMarkdownChanged,
            onLayoutChanged: (v) => setState(() => _markdownLayout = v),
          ),
          if (!_isMarkdown) NoteRichToolbar(controller: _controller!),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isMarkdown
                  ? MarkdownEditorArea(
                      controller: _markdownController,
                      layout: _markdownLayout,
                    )
                  : Directionality(
                      textDirection:
                          _looksArabic(_controller!.document.toPlainText())
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: quill.QuillEditor.basic(
                        controller: _controller!,
                        config: const quill.QuillEditorConfig(),
                      ),
                    ),
            ),
          ),
          VoiceNotesSection(note: note, embedService: _embedService),
          SizedBox(height: widget.navBarStyle.contentPadding),
        ],
      ),
    );
  }

  void _onMarkdownChanged(bool value) {
    setState(() {
      _isMarkdown = value;
      if (_isMarkdown &&
          _markdownController.text.isEmpty &&
          _controller != null) {
        _markdownController.text = _controller!.document.toPlainText();
      }
    });
  }

  Future<void> _save(NoteController notes) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (_isMarkdown) {
      final text = _markdownController.text;
      final doc = quill.Document()..insert(0, text.isEmpty ? '\n' : '$text\n');
      _controller = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    await notes.saveEditor(
      noteId: widget.note.id,
      title: _title.text,
      contentDeltaJson: jsonEncode(_controller!.document.toDelta().toJson()),
      isMarkdown: _isMarkdown,
    );

    if (!mounted) return;
    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Saved')));
    navigator.pop();
  }

  quill.QuillController _buildController(NoteEntity note) {
    try {
      final decoded = jsonDecode(note.contentDeltaJson);
      final doc = quill.Document.fromJson(
        (decoded as List).cast<Map<String, dynamic>>(),
      );
      return quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      final doc = quill.Document()..insert(0, ' ');
      return quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
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
