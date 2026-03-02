import 'package:flutter/material.dart';
import 'package:nexus/features/notes/domain/entities/note_attachment_entity.dart';

/// Voice note item widget
class VoiceNoteItem extends StatelessWidget {
  const VoiceNoteItem({
    super.key,
    required this.attachment,
    required this.onPlay,
  });

  final NoteAttachmentEntity attachment;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Note',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  attachment.uploaded ? 'Synced' : 'Local only',
                  style: TextStyle(
                    fontSize: 11,
                    color: attachment.uploaded
                        ? Colors.green
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (attachment.uploaded)
            const Icon(Icons.cloud_done, size: 16, color: Colors.green),
        ],
      ),
    );
  }
}
