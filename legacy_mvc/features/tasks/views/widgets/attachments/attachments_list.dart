import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/models/task.dart';
import 'package:nexus/features/tasks/views/widgets/attachments/attachment_tile.dart';

/// A widget that displays a list of attachments for a task.
class AttachmentsList extends StatelessWidget {
  const AttachmentsList({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    if (task.attachments.isEmpty) {
      return const Text('No attachments');
    }

    final items = task.attachments;
    return Column(
      children: [
        for (final a in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AttachmentTile(attachment: a),
          ),
      ],
    );
  }
}
