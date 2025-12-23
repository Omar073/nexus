import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/extensions/l10n_x.dart';
import 'package:nexus/features/wrapper/views/widgets/drawer_item.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primaryContainer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.hub_outlined,
                  size: 48,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  'Nexus',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your productivity hub',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          DrawerItem(
            icon: Icons.insights_outlined,
            label: l10n.navHabits,
            onTap: () {
              Navigator.pop(context);
              context.go('/habits');
            },
          ),
          DrawerItem(
            icon: Icons.calendar_month_outlined,
            label: l10n.navCalendar,
            onTap: () {
              Navigator.pop(context);
              context.go('/calendar');
            },
          ),
          DrawerItem(
            icon: Icons.analytics_outlined,
            label: l10n.navAnalytics,
            onTap: () {
              Navigator.pop(context);
              context.go('/analytics');
            },
          ),
        ],
      ),
    );
  }
}
