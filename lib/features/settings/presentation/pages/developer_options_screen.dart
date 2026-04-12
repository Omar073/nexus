import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:nexus/core/services/notifications/reminder_notifications.dart';
import 'package:nexus/core/widgets/nexus_card.dart';
import 'package:provider/provider.dart';

/// Reserved notification id for debug test posts (avoid collision with reminder ids).
const int kDeveloperTestNotificationId = 0x7E57C0DE;

/// Debug-only tools (reachable from Settings when [kDebugMode]).
class DeveloperOptionsScreen extends StatelessWidget {
  const DeveloperOptionsScreen({super.key, this.notifications});

  /// Test injection; production uses [NotificationService] from [Provider].
  final ReminderNotifications? notifications;

  ReminderNotifications _notifications(BuildContext context) =>
      notifications ?? context.read<NotificationService>();

  Future<void> _showTestReminderNotification(BuildContext context) async {
    await _notifications(context).showNow(
      id: kDeveloperTestNotificationId,
      title: 'Reminder',
      body: 'Developer test — Nexus reminder-style notification',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Test notification posted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportsLocalNotifications =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Developer options')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            if (!supportsLocalNotifications)
              NexusCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                borderRadius: 16,
                child: Text(
                  'Local notifications are only exercised on Android and iOS.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              NexusCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                borderRadius: 16,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.notifications_active_outlined,
                    color: theme.colorScheme.onSurface,
                  ),
                  title: const Text('Show test reminder notification'),
                  subtitle: Text(
                    'Same channel and actions as real reminders. '
                    'Complete/Snooze need a matching reminder in Hive to take effect.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  onTap: () => _showTestReminderNotification(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
