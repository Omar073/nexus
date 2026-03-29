// Inserts an inline placeholder for an attachment (e.g. [[voice:id]],
// [[image:id]]) into the note at the current cursor/selection.
//
// Markdown mode writes into [TextEditingController] (surrounds the marker
// with newlines). Rich-text mode inserts into the Quill document as plain
// text so markers round-trip with the note and stay visible in the editor.

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Inserts Quill markers for attachments in note content.

class NoteEditorMarkerInserter {
  const NoteEditorMarkerInserter();

  void insert({
    required bool isMarkdown,
    required TextEditingController markdownController,
    required quill.QuillController quillController,
    required String marker,
  }) {
    if (isMarkdown) {
      final text = markdownController.text;
      final selection = markdownController.selection;
      final rawIndex = selection.isValid ? selection.start : text.length;
      final safeIndex = rawIndex.clamp(0, text.length).toInt();
      final insertion = '\n$marker\n';
      final updated = text.replaceRange(safeIndex, safeIndex, insertion);
      markdownController.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(
          offset: safeIndex + insertion.length,
        ),
      );
      return;
    }

    final rawOffset = quillController.selection.baseOffset;
    final safeOffset = rawOffset < 0
        ? quillController.document.length - 1
        : rawOffset;
    final insertion = '$marker ';
    quillController.document.insert(safeOffset, insertion);
    quillController.updateSelection(
      TextSelection.collapsed(offset: safeOffset + insertion.length),
      quill.ChangeSource.local,
    );
  }
}
