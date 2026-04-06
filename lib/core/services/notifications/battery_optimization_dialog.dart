import 'package:flutter/material.dart';
import 'package:nexus/app/router/app_router.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';

/// Shows an explanation dialog, then requests the OS battery optimization
/// exemption if the user accepts. Returns `true` when the exemption is granted.
///
/// Uses [rootNavigatorKey] so this can be called from anywhere (services,
/// callbacks, widgets) without threading a [BuildContext] through the call
/// chain. Returns `false` if the navigator is not yet available.
Future<bool> showBatteryOptimizationExplanation(
  NotificationService notificationService,
) async {
  final context = rootNavigatorKey.currentContext;
  if (context == null) return false;

  final accepted = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Keep Reminders Reliable'),
      content: const Text(
        'Android may delay or silence notifications to save battery. '
        'To make sure your reminders arrive on time, please allow '
        'Nexus to run without battery restrictions.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Not Now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Allow'),
        ),
      ],
    ),
  );

  if (accepted == true) {
    return notificationService.requestBatteryOptimizationExemption();
  }
  return false;
}
