import 'package:flutter/material.dart';
import 'package:nexus/core/services/notifications/notification_service.dart';
import 'package:nexus/features/settings/presentation/pages/developer_options_screen.dart';
import 'package:nexus/features/settings/presentation/widgets/settings_section.dart';
import 'package:provider/provider.dart';

/// Entry for [DeveloperOptionsScreen]. Parent should only build this when
/// [kDebugMode] is true (e.g. from [SettingsScreen]).
class DeveloperOptionsSection extends StatelessWidget {
  const DeveloperOptionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Developer',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.developer_mode_outlined),
        title: const Text('Developer options'),
        subtitle: const Text('Debug build only — tools for local testing'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          final notifications = context.read<NotificationService>();
          final theme = Theme.of(context);
          Navigator.of(context, rootNavigator: true).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => Theme(
                data: theme,
                child: Provider<NotificationService>.value(
                  value: notifications,
                  child: const DeveloperOptionsScreen(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
