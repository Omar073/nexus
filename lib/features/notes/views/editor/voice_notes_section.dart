import 'package:flutter/material.dart';
import 'package:nexus/core/services/note_embed_service.dart';
import 'package:nexus/core/widgets/nexus_card.dart';
import 'package:nexus/features/notes/models/note.dart';
import 'package:nexus/features/notes/views/editor/voice_note_item.dart';

class VoiceNotesSection extends StatelessWidget {
  const VoiceNotesSection({
    super.key,
    required this.note,
    required this.embedService,
  });

  final Note note;
  final NoteEmbedService embedService;

  @override
  Widget build(BuildContext context) {
    if (note.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
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
                  await embedService.playLocal(path);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

