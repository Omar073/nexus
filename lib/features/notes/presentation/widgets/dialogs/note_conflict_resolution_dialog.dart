import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nexus/core/services/sync/models/sync_conflict.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/features/notes/data/models/note.dart';
import 'package:nexus/features/sync/presentation/state_management/sync_controller.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

/// Lets the user pick local vs remote when a note conflicts.

class NoteConflictResolutionDialog extends StatefulWidget {
  const NoteConflictResolutionDialog({super.key});

  @override
  /// Creates the mutable state for this dialog.
  State<NoteConflictResolutionDialog> createState() =>
      _NoteConflictResolutionDialogState();
}

class _NoteConflictResolutionDialogState
    extends State<NoteConflictResolutionDialog> {
  int _index = 0;
  static const _uuid = Uuid();

  @override
  /// Builds the conflict resolution dialog: dropdown to pick conflict, side-by-side note cards, and Keep Local/Remote actions.
  Widget build(BuildContext context) {
    final sync = context.watch<SyncController>();
    final conflicts = sync.noteConflicts;

    if (conflicts.isEmpty) {
      return AlertDialog(
        title: const Text('Note conflicts'),
        content: const Text('No note conflicts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    }

    final selected = conflicts[_index.clamp(0, conflicts.length - 1)];
    final local = selected.local;
    final remote = selected.remote;

    return AlertDialog(
      title: const Text('Resolve note sync conflict'),
      content: SizedBox(
        width: 900,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Conflict:'),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<int>(
                    value: _index.clamp(0, conflicts.length - 1),
                    isExpanded: true,
                    items: [
                      for (var i = 0; i < conflicts.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(conflicts[i].local.title ?? 'Untitled'),
                        ),
                    ],
                    onChanged: (v) => setState(() => _index = v ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _NoteSnapshotCard(title: 'Local', note: local),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NoteSnapshotCard(title: 'Remote', note: remote),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _keepRemote(context, selected),
          child: const Text('Keep Remote'),
        ),
        FilledButton(
          onPressed: () => _keepLocal(context, selected),
          child: const Text('Keep Local'),
        ),
      ],
    );
  }

  /// Accepts the remote version: writes it to Hive, marks synced, and removes the conflict.
  Future<void> _keepRemote(
    BuildContext context,
    SyncConflict<Note> conflict,
  ) async {
    final notesBox = Hive.box<Note>(HiveBoxes.notes);
    final remote = conflict.remote;
    remote.isDirty = false;
    remote.lastSyncedAt = DateTime.now();
    remote.syncStatusEnum = SyncStatus.synced;
    await notesBox.put(remote.id, remote);
    if (!context.mounted) return;
    _removeConflict(context, conflict.entityId);
  }

  /// Keeps the local version: saves it, enqueues an update sync op, and removes the conflict.
  Future<void> _keepLocal(
    BuildContext context,
    SyncConflict<Note> conflict,
  ) async {
    final syncService = context.read<SyncService>();
    final local = conflict.local;
    local.isDirty = true;
    local.syncStatusEnum = SyncStatus.idle;
    await local.save();

    final op = SyncOperation(
      id: _uuid.v4(),
      type: SyncOperationType.update.index,
      entityType: 'note',
      entityId: local.id,
      createdAt: DateTime.now(),
      data: local.toFirestoreJson(),
    );
    await syncService.enqueueOperation(op);
    await syncService.syncOnce();
    if (!context.mounted) return;
    _removeConflict(context, conflict.entityId);
  }

  /// Removes the resolved conflict from the list; closes the dialog if no conflicts remain.
  void _removeConflict(BuildContext context, String entityId) {
    final sync = context.read<SyncController>();
    final remaining = sync.noteConflicts
        .where((c) => c.entityId != entityId)
        .toList();
    sync.replaceNoteConflicts(remaining);
    if (remaining.isEmpty && context.mounted) Navigator.of(context).pop();
  }
}

class _NoteSnapshotCard extends StatelessWidget {
  const _NoteSnapshotCard({required this.title, required this.note});

  final String title;
  final Note note;

  @override
  /// Builds a card showing note title and a plain-text preview of the content.
  Widget build(BuildContext context) {
    /// Extracts plain text from note contentDeltaJson for preview (max 400 chars).
    String preview(Note n) {
      try {
        final decoded = jsonDecode(n.contentDeltaJson);
        final doc = quill.Document.fromJson(
          (decoded as List).cast<Map<String, dynamic>>(),
        );
        final t = doc.toPlainText().trim();
        return t.isEmpty
            ? '—'
            : (t.length > 400 ? '${t.substring(0, 400)}…' : t);
      } catch (_) {
        return '—';
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              note.title ?? 'Untitled',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(preview(note), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
