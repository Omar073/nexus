import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Formatting toolbar for the Quill-based editor.
class NoteRichToolbar extends StatelessWidget {
  const NoteRichToolbar({super.key, required this.controller});

  final quill.QuillController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
        controller: controller,
        config: const quill.QuillSimpleToolbarConfig(
          showFontFamily: false,
          showFontSize: false,
          showCodeBlock: false,
          showInlineCode: false,
          showSearchButton: false,
          multiRowsDisplay: false,
        ),
      ),
    );
  }
}
