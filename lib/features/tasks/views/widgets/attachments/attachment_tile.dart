import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/models/task_attachment.dart';
import 'package:nexus/features/tasks/views/widgets/attachments/audio_player_tile.dart';

/// A tile widget for displaying a single attachment.
class AttachmentTile extends StatelessWidget {
  const AttachmentTile({super.key, required this.attachment});

  final TaskAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final uri = attachment.localUri;
    final mime = attachment.mimeType;
    if (uri == null) return const SizedBox.shrink();

    if (mime.startsWith('image/')) {
      final file = File(uri);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(file, height: 180, fit: BoxFit.cover),
      );
    }

    if (mime.startsWith('audio/')) {
      return AudioPlayerTile(path: uri);
    }

    return ListTile(
      leading: const Icon(Icons.attach_file),
      title: Text(File(uri).uri.pathSegments.last),
      subtitle: Text(mime),
    );
  }
}
