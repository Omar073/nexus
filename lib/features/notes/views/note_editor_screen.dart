import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nexus/core/services/note_embed_service.dart';
import 'package:nexus/core/widgets/nexus_card.dart';
import 'package:nexus/features/notes/controllers/note_controller.dart';
import 'package:nexus/features/notes/models/note.dart';
import 'package:nexus/features/notes/views/editor/attachment_button.dart';
import 'package:nexus/features/notes/views/editor/category_selector.dart';
import 'package:nexus/features/notes/views/editor/voice_note_item.dart';
import 'package:nexus/features/notes/views/editor/voice_recorder_button.dart';
import 'package:provider/provider.dart';

/// Note editor screen following Nexus design system.
/// Features styled title input, enhanced toolbar, and voice notes section.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, required this.noteId});
  final String noteId;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  quill.QuillController? _controller;
  final _title = TextEditingController();
  final _embedService = NoteEmbedService();

  bool _titleInitialized = false;

  @override
  void dispose() {
    _controller?.dispose();
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notes = context.watch<NoteController>();
    final note = notes.byId(widget.noteId);
    if (note == null) {
      return const Scaffold(body: Center(child: Text('Note not found')));
    }

    _controller ??= _buildController(note);
    if (!_titleInitialized) {
      _title.text = note.title ?? '';
      _titleInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Voice note button
          VoiceRecorderButton(note: note),
          // Image attachment button
          AttachmentButton(note: note),
          // Save button
          FilledButton.icon(
            onPressed: () async {
              await notes.saveEditor(
                note: note,
                controller: _controller!,
                title: _title.text,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Saved')));
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Save'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Title input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Untitled',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Category Selector
          CategorySelector(note: note),
          // Toolbar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300,
              ),
            ),
            child: quill.QuillSimpleToolbar(
              controller: _controller!,
              config: const quill.QuillSimpleToolbarConfig(
                showFontFamily: false,
                showFontSize: false,
                showCodeBlock: false,
                showInlineCode: false,
                showSearchButton: false,
                multiRowsDisplay: false,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Editor
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Directionality(
                textDirection: _looksArabic(_controller!.document.toPlainText())
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: quill.QuillEditor.basic(
                  controller: _controller!,
                  config: const quill.QuillEditorConfig(),
                ),
              ),
            ),
          ),
          // Attachments section
          if (note.attachments.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: NexusCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.mic,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Voice Notes',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${note.attachments.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...note.attachments.map(
                      (a) => VoiceNoteItem(
                        attachment: a,
                        onPlay: () async {
                          final path = a.localUri;
                          if (path == null) return;
                          await _embedService.playLocal(path);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  quill.QuillController _buildController(Note note) {
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
