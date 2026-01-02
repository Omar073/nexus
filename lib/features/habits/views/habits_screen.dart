import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/app/router/app_routes.dart';
import 'package:nexus/core/widgets/nexus_card.dart';
import 'package:nexus/features/habits/controllers/habit_controller.dart';
import 'package:nexus/features/habits/models/habit.dart';
import 'package:nexus/features/habits/views/habit_details_screen.dart';
import 'package:nexus/features/habits/views/widgets/habit_create_dialog.dart';
import 'package:provider/provider.dart';
import 'package:nexus/core/widgets/app_drawer_button.dart';
import 'package:nexus/features/wrapper/views/app_drawer.dart';

/// Habits screen following Nexus design system.
/// Features large header with drawer button, habit cards with streak info.
class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<HabitController>();
    final habits = controller.habits;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const AppDrawerButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () {
              context.push(AppRoute.calendar.path);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Habits',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Build consistency, one day at a time',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Habits list
            Expanded(
              child: habits.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.loop,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No habits yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to create your first habit',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: habits.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _HabitCard(habit: habits[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'habits_fab',
        onPressed: () => showHabitCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Styled habit card widget
class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.habit});

  final Habit habit;

  IconData _getHabitIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('water') || lowerTitle.contains('drink')) {
      return Icons.water_drop;
    }
    if (lowerTitle.contains('meditat') || lowerTitle.contains('mindful')) {
      return Icons.self_improvement;
    }
    if (lowerTitle.contains('exercise') ||
        lowerTitle.contains('gym') ||
        lowerTitle.contains('workout')) {
      return Icons.fitness_center;
    }
    if (lowerTitle.contains('read')) {
      return Icons.menu_book;
    }
    if (lowerTitle.contains('sleep') || lowerTitle.contains('bed')) {
      return Icons.bedtime;
    }
    if (lowerTitle.contains('walk') || lowerTitle.contains('step')) {
      return Icons.directions_walk;
    }
    if (lowerTitle.contains('journal') || lowerTitle.contains('write')) {
      return Icons.edit_note;
    }
    return Icons.loop;
  }

  Color _getHabitColor(String title, ThemeData theme) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('water')) return Colors.cyan;
    if (lowerTitle.contains('meditat')) return Colors.purple;
    if (lowerTitle.contains('exercise') || lowerTitle.contains('gym')) {
      return Colors.orange;
    }
    if (lowerTitle.contains('read')) return Colors.green;
    if (lowerTitle.contains('sleep')) return Colors.indigo;
    return theme.colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final icon = _getHabitIcon(habit.title);
    final color = _getHabitColor(habit.title, theme);

    return NexusCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HabitDetailsScreen(habitId: habit.id),
          ),
        );
      },
      child: Row(
        children: [
          // Icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? color.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '0 day streak', // TODO: Calculate actual streak
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: habit.active
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              habit.active ? 'Active' : 'Paused',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: habit.active ? theme.colorScheme.primary : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
