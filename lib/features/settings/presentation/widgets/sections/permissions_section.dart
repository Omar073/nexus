import 'package:flutter/material.dart';
import 'package:nexus/core/services/notifications/battery_optimization_dialog.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:nexus/core/services/platform/permission_service.dart';
import 'package:provider/provider.dart';

/// Explains and requests OS permissions.
class PermissionsSection extends StatelessWidget {
  const PermissionsSection({super.key});

  Future<void> _requestReminderPermissions(BuildContext context) async {
    final permissionService = context.read<PermissionService>();
    final notificationService = context.read<NotificationService>();

    await permissionService.ensureNotifications();

    if (!context.mounted) return;

    final alreadyExempt = await notificationService
        .isBatteryOptimizationExempt();
    if (!alreadyExempt) {
      await showBatteryOptimizationExplanation(notificationService);
    }
  }

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
          title: const Text('Reminders'),
          subtitle: const Text(
            'Notifications & battery optimization for reliable reminders',
          ),
          trailing: OutlinedButton(
            onPressed: () => _requestReminderPermissions(context),
            child: const Text('Request'),
          ),
        ),
      ],
    );
  }
}
