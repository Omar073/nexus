import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/core/widgets/habit_pill.dart';
import 'package:nexus/core/widgets/section_header.dart';
import 'package:nexus/features/dashboard/views/widgets/daily_progress_card.dart';
import 'package:nexus/features/dashboard/views/widgets/quick_reminder_card.dart';
import 'package:nexus/features/dashboard/views/widgets/upcoming_task_card.dart';
import 'package:nexus/features/habits/controllers/habit_controller.dart';
import 'package:nexus/features/reminders/controllers/reminder_controller.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/task.dart';
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Open menu',
          ),
        ),
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
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
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
                    const SnackBar(content: Text('Focus mode coming soon!')),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            SectionHeader(
              title: 'Habits',
              padding: const EdgeInsets.symmetric(horizontal: 24),
              onViewAll: () {
                Navigator.of(context).pushNamed('/habits');
              },
            ),
            const SizedBox(height: 12),
            _buildHabitsSection(context),

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
                  _buildRemindersGrid(context),
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
                  _buildUpcomingTasks(context, activeTasks),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsSection(BuildContext context) {
    // Try to get habits from controller, use demo data if empty
    final habitController = context.watch<HabitController>();
    final habits = habitController.habits;

    if (habits.isEmpty) {
      // Demo habits
      return HabitPillBar(
        habits: [
          HabitPillData(
            icon: Icons.water_drop,
            label: 'Water 0/3L',
            iconColor: Colors.cyan,
          ),
          HabitPillData(
            icon: Icons.self_improvement,
            label: 'Meditation',
            iconColor: Colors.pink.shade300,
          ),
          HabitPillData(
            icon: Icons.fitness_center,
            label: 'Gym',
            iconColor: Colors.blue,
            isCompleted: true,
          ),
          HabitPillData(
            icon: Icons.menu_book,
            label: 'Read 10 pages',
            iconColor: Colors.green,
          ),
        ],
      );
    }

    return HabitPillBar(
      habits: habits
          .take(5)
          .map(
            (h) => HabitPillData(
              icon: Icons.check_circle_outline,
              label: h.title,
              iconColor: Theme.of(context).colorScheme.primary,
              isCompleted:
                  false, // Habit model doesn't have completion tracking yet
            ),
          )
          .toList(),
    );
  }

  Widget _buildRemindersGrid(BuildContext context) {
    final reminderController = context.watch<ReminderController>();
    final reminders = reminderController.reminders;

    if (reminders.isEmpty) {
      // Empty state for reminders
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(
                Icons.alarm_off,
                size: 32,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No reminders',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final upcomingReminders = reminders.take(4).toList();
    return QuickRemindersGrid(
      reminders: upcomingReminders
          .map(
            (r) => QuickReminderData(
              timeLabel: DateFormat.jm().format(r.time),
              title: r.title,
              subtitle: 'Reminder',
              accentColor: Colors.orange,
            ),
          )
          .toList(),
    );
  }

  Widget _buildUpcomingTasks(BuildContext context, List<Task> tasks) {
    final theme = Theme.of(context);

    if (tasks.isEmpty) {
      // Empty state for tasks
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(
                Icons.task_alt,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No upcoming tasks',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final taskController = context.read<TaskController>();
    return Column(
      children: tasks.take(5).map<Widget>((t) {
        final isCompleted = t.statusEnum == TaskStatus.completed;
        final isHighPriority = t.priorityEnum == TaskPriority.high;
        final categoryLabel = t.categoryId ?? 'Task';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: UpcomingTaskCard(
            title: t.title,
            subtitle: t.dueDate != null
                ? 'Due ${DateFormat.jm().format(t.dueDate!)} • $categoryLabel'
                : categoryLabel,
            isCompleted: isCompleted,
            isHighPriority: isHighPriority,
            onToggle: (value) {
              taskController.toggleCompleted(t, value);
            },
          ),
        );
      }).toList(),
    );
  }
}
