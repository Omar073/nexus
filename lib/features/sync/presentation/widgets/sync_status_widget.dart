import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/features/sync/presentation/state_management/sync_controller.dart';
import 'package:nexus/features/tasks/presentation/widgets/task_conflict_resolution_dialog.dart';
import 'package:nexus/features/notes/presentation/widgets/dialogs/note_conflict_resolution_dialog.dart';
import 'package:provider/provider.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SyncController>();
    final hasTaskConflicts = controller.conflicts.isNotEmpty;
    final hasNoteConflicts = controller.noteConflicts.isNotEmpty;
    final hasConflicts = controller.hasAnyConflicts;

    IconData icon;
    Color? color;
    String tooltip;

    if (hasConflicts) {
      icon = Icons.error_outline;
      color = Theme.of(context).colorScheme.error;
      tooltip = 'Sync conflicts need review';
    } else if (controller.isSyncing) {
      icon = Icons.sync;
      tooltip = 'Syncing...';
    } else if (controller.queueCount > 0) {
      icon = Icons.cloud_upload_outlined;
      tooltip = 'Pending sync: ${controller.queueCount}';
    } else {
      icon = Icons.cloud_done_outlined;
      final ts = controller.lastSuccessfulSyncAt;
      tooltip = ts == null
          ? 'Not synced yet'
          : 'Last sync: ${DateFormat.Hm().format(ts)}';
    }

    return IconButton(
      onPressed: () async {
        if (hasConflicts) {
          if (hasTaskConflicts) {
            await showDialog<void>(
              context: context,
              builder: (_) => const TaskConflictResolutionDialog(),
            );
            return;
          }
          if (hasNoteConflicts) {
            await showDialog<void>(
              context: context,
              builder: (_) => const NoteConflictResolutionDialog(),
            );
            return;
          }
        }
        await controller.syncNow();
      },
      tooltip: tooltip,
      icon: Icon(icon, color: color),
    );
  }
}
