import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/core/widgets/nexus_card.dart';
import 'package:nexus/features/notes/models/note.dart';
import 'package:nexus/features/notes/views/note_editor_screen.dart';

/// Styled note tile following Nexus design.
/// Shows title, preview, and timestamp.
class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note});

  final Note note;

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = note.title ?? 'Untitled';
    // Extract plain text from delta JSON for preview (simplified)
    final preview = _extractPreview(note.contentDeltaJson);

    return NexusCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: note.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimestamp(note.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          // Preview text
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              preview,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// Simple extraction of text from Quill Delta JSON
  String _extractPreview(String deltaJson) {
    // Basic extraction - look for "insert" text segments
    try {
      if (deltaJson.isEmpty || deltaJson == '[]') return '';
      // Simple regex to extract text from delta format
      final insertPattern = RegExp(r'"insert"\s*:\s*"([^"]*)"');
      final matches = insertPattern.allMatches(deltaJson);
      final buffer = StringBuffer();
      for (final match in matches) {
        if (match.groupCount > 0) {
          buffer.write(match.group(1));
        }
      }
      return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
    } catch (_) {
      return '';
    }
  }
}
