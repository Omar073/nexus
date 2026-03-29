import 'package:flutter/material.dart';
import 'package:nexus/features/sync/presentation/state_management/sync_controller.dart';
import 'package:nexus/features/tasks/presentation/widgets/task_conflict_resolution_dialog.dart';
import 'package:nexus/features/notes/presentation/widgets/dialogs/note_conflict_resolution_dialog.dart';
import 'package:provider/provider.dart';

/// Manual sync triggers and last-sync messaging.
class SyncSection extends StatelessWidget {
  const SyncSection({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncController>();
    final hasTaskConflicts = sync.conflicts.isNotEmpty;
    final hasNoteConflicts = sync.noteConflicts.isNotEmpty;
    final hasConflicts = sync.hasAnyConflicts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sync', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            hasConflicts ? Icons.error_outline : Icons.cloud_outlined,
            color: hasConflicts ? Theme.of(context).colorScheme.error : null,
          ),
          title: Text('Queue: ${sync.queueCount}'),
          subtitle: Text(
            sync.lastSuccessfulSyncAt == null
                ? 'Last sync: —'
                : 'Last sync: ${sync.lastSuccessfulSyncAt}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasConflicts)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (hasTaskConflicts) {
                        await showDialog<void>(
                          context: context,
                          builder: (_) => const TaskConflictResolutionDialog(),
                        );
                      } else if (hasNoteConflicts) {
                        await showDialog<void>(
                          context: context,
                          builder: (_) => const NoteConflictResolutionDialog(),
                        );
                      }
                    },
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: Text(
                      hasTaskConflicts && hasNoteConflicts
                          ? 'Resolve conflicts'
                          : hasTaskConflicts
                          ? 'Resolve task conflicts'
                          : 'Resolve note conflicts',
                    ),
                  ),
                ),
              FilledButton(
                onPressed: sync.syncNow,
                child: const Text('Sync now'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
