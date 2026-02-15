import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/app/router/app_routes.dart';
import 'package:nexus/core/widgets/section_header.dart';
import 'package:nexus/features/dashboard/views/widgets/daily_progress_card.dart';
import 'package:nexus/features/dashboard/views/widgets/dashboard_habits_section.dart';
import 'package:nexus/features/dashboard/views/widgets/dashboard_reminders_section.dart';
import 'package:nexus/features/dashboard/views/widgets/dashboard_tasks_section.dart';
import 'package:nexus/core/widgets/app_drawer_button.dart';

import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/settings/models/nav_bar_style.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task_enums.dart';
import 'package:provider/provider.dart';

/// Dashboard screen following Nexus design system.
/// Shows profile header, daily progress, habits, reminders, and upcoming tasks.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMM d');

    // Get data from controllers
    final taskController = context.watch<TaskController>();

    // Get all tasks from all statuses
    final activeTasks = taskController.tasksForStatus(TaskStatus.active);
    final pendingTasks = taskController.tasksForStatus(TaskStatus.pending);
    final completedTasks = taskController.tasksForStatus(TaskStatus.completed);

    // Filter today's tasks
    final todaysTasks = [...activeTasks, ...pendingTasks, ...completedTasks]
        .where((t) {
          final due = t.dueDate;
          return due != null &&
              due.year == now.year &&
              due.month == now.month &&
              due.day == now.day;
        })
        .toList();

    final completedToday = todaysTasks
        .where((t) => t.statusEnum == TaskStatus.completed)
        .length;

    return Scaffold(
      appBar: AppBar(
        leading: const AppDrawerButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final navBarStyle = context.watch<SettingsController>().navBarStyle;
            return ListView(
              padding: EdgeInsets.only(bottom: navBarStyle.contentPadding),
              children: [
                // Profile Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormat.format(now).toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_getGreeting()}, Omar',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      // Profile avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          border: Border.all(
                            color: isDark ? Colors.grey.shade700 : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Daily Progress Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: DailyProgressCard(
                    tasksCompleted: completedToday,
                    totalTasks: todaysTasks.length + activeTasks.length,
                    onViewFocusMode: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Focus mode coming soon!'),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                SectionHeader(
                  title: 'Habits',
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  onViewAll: () {
                    context.push(AppRoute.habits.path);
                  },
                ),
                const SizedBox(height: 12),
                const DashboardHabitsSection(),

                const SizedBox(height: 24),

                // Quick Reminders Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Reminders',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const DashboardRemindersSection(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Upcoming Tasks Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Tasks',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DashboardTasksSection(tasks: activeTasks),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
