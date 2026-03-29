import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/app/router/app_routes.dart';
import 'package:nexus/features/wrapper/presentation/widgets/drawer_item.dart';

/// Navigation drawer destinations and header.

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
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
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            onTap: () {
              Navigator.pop(context);
              context.go(AppRoute.dashboard.path);
            },
          ),
          DrawerItem(
            icon: Icons.insights_outlined,
            label: 'Habits',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoute.habits.path);
            },
          ),
          DrawerItem(
            icon: Icons.calendar_month_outlined,
            label: 'Calendar',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoute.calendar.path);
            },
          ),
          DrawerItem(
            icon: Icons.analytics_outlined,
            label: 'Analytics',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoute.analytics.path);
            },
          ),
        ],
      ),
    );
  }
}
