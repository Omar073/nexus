import 'package:flutter/material.dart';
import 'package:nexus/features/notes/presentation/widgets/editor/markdown/markdown_editor_area.dart';

/// Toggles between markdown and rich text for a note.
class NoteMarkdownToggleRow extends StatelessWidget {
  const NoteMarkdownToggleRow({
    super.key,
    required this.isMarkdown,
    required this.layout,
    required this.onMarkdownChanged,
    required this.onLayoutChanged,
  });

  final bool isMarkdown;
  final MarkdownLayout layout;
  final ValueChanged<bool> onMarkdownChanged;
  final ValueChanged<MarkdownLayout> onLayoutChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.code, size: 18),
                const SizedBox(width: 8),
                Text('Markdown mode', style: theme.textTheme.bodyMedium),
                const Spacer(),
                Switch(value: isMarkdown, onChanged: onMarkdownChanged),
              ],
            ),
          ),
          if (isMarkdown) ...[
            const SizedBox(width: 12),
            ToggleButtons(
              isSelected: [
                layout == MarkdownLayout.tabs,
                layout == MarkdownLayout.split,
              ],
              borderRadius: BorderRadius.circular(8),
              onPressed: (index) {
                onLayoutChanged(
                  index == 0 ? MarkdownLayout.tabs : MarkdownLayout.split,
                );
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(Icons.tab),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(Icons.splitscreen),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
