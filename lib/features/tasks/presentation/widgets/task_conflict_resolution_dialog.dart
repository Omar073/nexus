import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/core/data/hive/hive_boxes.dart';
import 'package:nexus/core/data/sync_queue.dart';
import 'package:nexus/core/services/sync/sync_service.dart';
import 'package:nexus/core/services/sync/models/sync_conflict.dart';
import 'package:nexus/features/sync/presentation/state_management/sync_controller.dart';
import 'package:nexus/features/tasks/data/models/task.dart';
import 'package:nexus/features/tasks/domain/task_enums.dart';
import 'package:nexus/features/tasks/presentation/widgets/task_conflict_snapshot_card.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

/// Resolves task edit conflicts (local vs remote).

class TaskConflictResolutionDialog extends StatefulWidget {
  const TaskConflictResolutionDialog({super.key});

  /// Wraps the dialog with the required sync providers.
  static Widget wrapWithRequiredProviders(BuildContext context) {
    final sync = context.read<SyncController>();
    final service = context.read<SyncService>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SyncController>.value(value: sync),
        Provider<SyncService>.value(value: service),
      ],
      child: const TaskConflictResolutionDialog(),
    );
  }

  @override
  State<TaskConflictResolutionDialog> createState() =>
      _TaskConflictResolutionDialogState();
}

class _TaskConflictResolutionDialogState
    extends State<TaskConflictResolutionDialog> {
  int _index = 0;
  static const _uuid = Uuid();

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncController>();
    final conflicts = sync.conflicts;

    if (conflicts.isEmpty) {
      return AlertDialog(
        title: const Text('Conflicts'),
        content: const Text('No conflicts.'),
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
      title: const Text('Resolve sync conflict'),
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
                          child: Text(conflicts[i].local.title),
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
                  child: TaskConflictSnapshotCard(
                    title: 'Local',
                    task: local,
                    other: remote,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TaskConflictSnapshotCard(
                    title: 'Remote',
                    task: remote,
                    other: local,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tip: pick which version should win. "Keep Local" will overwrite cloud; "Keep Remote" will overwrite this device.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
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

  Future<void> _keepRemote(
    BuildContext context,
    SyncConflict<Task> conflict,
  ) async {
    final tasksBox = Hive.box<Task>(HiveBoxes.tasks);
    final remote = conflict.remote;
    remote.isDirty = false;
    remote.lastSyncedAt = DateTime.now();
    remote.syncStatusEnum = SyncStatus.synced;
    await tasksBox.put(remote.id, remote);

    if (!context.mounted) return;
    _removeConflict(context, conflict.entityId);
  }

  Future<void> _keepLocal(
    BuildContext context,
    SyncConflict<Task> conflict,
  ) async {
    final syncService = context.read<SyncService>();
    final local = conflict.local;
    local.syncStatusEnum = SyncStatus.idle;
    local.isDirty = true;
    await local.save();

    final op = SyncOperation(
      id: _uuid.v4(),
      type: SyncOperationType.update.index,
      entityType: 'task',
      entityId: local.id,
      createdAt: DateTime.now(),
      data: local.toFirestoreJson(),
    );
    await syncService.enqueueOperation(op);
    await syncService.syncOnce();

    if (!context.mounted) return;
    _removeConflict(context, conflict.entityId);
  }

  void _removeConflict(BuildContext context, String entityId) {
    final sync = context.read<SyncController>();
    final remaining = sync.conflicts
        .where((c) => c.entityId != entityId)
        .toList();
    sync.replaceConflicts(remaining);
    if (remaining.isEmpty && context.mounted) Navigator.of(context).pop();
  }
}
