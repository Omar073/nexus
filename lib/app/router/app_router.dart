import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/app/router/app_routes.dart';
import 'package:nexus/features/analytics/views/analytics_screen.dart';
import 'package:nexus/features/calendar/views/calendar_screen.dart';
import 'package:nexus/features/dashboard/views/dashboard_screen.dart';
import 'package:nexus/features/habits/views/habits_screen.dart';
import 'package:nexus/features/notes/views/notes_list_screen.dart';
import 'package:nexus/features/reminders/views/reminders_screen.dart';
import 'package:nexus/features/settings/views/settings_screen.dart';
import 'package:nexus/features/tasks/views/tasks_screen.dart';
import 'package:nexus/features/wrapper/views/app_wrapper.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static GoRouter create() {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: AppRoute.dashboard.path,
      routes: [
        StatefulShellRoute(
          builder: (context, state, navigationShell) => navigationShell,
          navigatorContainerBuilder: (context, navigationShell, children) {
            return AppWrapper(
              navigationShell: navigationShell,
              children: children,
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoute.dashboard.path,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: DashboardScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoute.tasks.path,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: TasksScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoute.reminders.path,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: RemindersScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoute.notes.path,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: NotesListScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoute.settings.path,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: SettingsScreen()),
                ),
              ],
            ),
          ],
        ),
        // Drawer items (outside of StatefulShellRoute for proper navigation)
        GoRoute(
          path: AppRoute.habits.path,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HabitsScreen()),
        ),
        GoRoute(
          path: AppRoute.calendar.path,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CalendarScreen()),
        ),
        GoRoute(
          path: AppRoute.analytics.path,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AnalyticsScreen()),
        ),
      ],
    );
  }
}
