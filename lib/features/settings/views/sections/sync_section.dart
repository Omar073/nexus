import 'package:flutter/material.dart';
import 'package:nexus/features/sync/controllers/sync_controller.dart';
import 'package:provider/provider.dart';

/// Sync status and controls section
class SyncSection extends StatelessWidget {
  const SyncSection({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sync', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            sync.conflicts.isNotEmpty
                ? Icons.error_outline
                : Icons.cloud_outlined,
            color: sync.conflicts.isNotEmpty
                ? Theme.of(context).colorScheme.error
                : null,
          ),
          title: Text('Queue: ${sync.queueCount}'),
          subtitle: Text(
            sync.lastSuccessfulSyncAt == null
                ? 'Last sync: —'
                : 'Last sync: ${sync.lastSuccessfulSyncAt}',
          ),
          trailing: FilledButton(
            onPressed: sync.syncNow,
            child: const Text('Sync now'),
          ),
        ),
      ],
    );
  }
}
