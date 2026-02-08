import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/nexus_card.dart';
import 'package:nexus/features/habits/models/habit.dart';
import 'package:nexus/features/habits/views/habit_details_screen.dart';

/// Styled habit card widget showing habit info with icon and streak.
class HabitCard extends StatelessWidget {
  const HabitCard({super.key, required this.habit});

  final Habit habit;

  static const _habitStyles =
      <({List<String> keywords, IconData icon, Color color})>[
        (
          keywords: ['water', 'drink', 'hydrat'],
          icon: Icons.water_drop,
          color: Colors.cyan,
        ),
        (
          keywords: ['meditat', 'mindful', 'breath'],
          icon: Icons.self_improvement,
          color: Colors.purple,
        ),
        (
          keywords: ['exercise', 'gym', 'workout', 'fitness'],
          icon: Icons.fitness_center,
          color: Colors.orange,
        ),
        (
          keywords: ['read', 'book'],
          icon: Icons.menu_book,
          color: Colors.green,
        ),
        (
          keywords: ['sleep', 'bed', 'rest'],
          icon: Icons.bedtime,
          color: Colors.indigo,
        ),
        (
          keywords: ['walk', 'step', 'run', 'jog'],
          icon: Icons.directions_walk,
          color: Colors.teal,
        ),
        (
          keywords: ['journal', 'write', 'diary'],
          icon: Icons.edit_note,
          color: Colors.amber,
        ),
        (
          keywords: ['code', 'program', 'develop'],
          icon: Icons.code,
          color: Colors.blue,
        ),
        (
          keywords: ['music', 'piano', 'guitar'],
          icon: Icons.music_note,
          color: Colors.pink,
        ),
        (
          keywords: ['cook', 'meal', 'food'],
          icon: Icons.restaurant,
          color: Colors.deepOrange,
        ),
      ];

  /// Default style when no keyword matches.
  static const _defaultIcon = Icons.loop;

  ({IconData icon, Color color}) _getHabitStyle(String title, ThemeData theme) {
    final lowerTitle = title.toLowerCase();

    for (final style in _habitStyles) {
      if (style.keywords.any((kw) => lowerTitle.contains(kw))) {
        return (icon: style.icon, color: style.color);
      }
    }

    return (icon: _defaultIcon, color: theme.colorScheme.primary);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final style = _getHabitStyle(habit.title, theme);
    final icon = style.icon;
    final color = style.color;

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
