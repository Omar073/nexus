import 'package:flutter/material.dart';
import 'package:nexus/core/services/platform/permission_service.dart';
import 'package:provider/provider.dart';

/// Explains and requests OS permissions.
class PermissionsSection extends StatelessWidget {
  const PermissionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Permissions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Notifications'),
          subtitle: const Text('Required for reminders'),
          trailing: OutlinedButton(
            onPressed: () =>
                context.read<PermissionService>().ensureNotifications(),
            child: const Text('Request'),
          ),
        ),
      ],
    );
  }
}
