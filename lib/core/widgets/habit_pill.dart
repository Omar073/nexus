import 'package:flutter/material.dart';

/// Horizontal scrolling habit pill bar following Nexus design.
/// Each habit is a pill with icon, label, and optional completion state.
class HabitPill extends StatelessWidget {
  const HabitPill({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    this.isCompleted = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final bool isCompleted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isCompleted
        ? theme.colorScheme.primary.withValues(alpha: 0.2)
        : isDark
        ? const Color(0xFF1C1C1E)
        : Colors.white;

    final borderColor = isCompleted
        ? theme.colorScheme.primary.withValues(alpha: 0.3)
        : isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.shade200;

    final textColor = isCompleted
        ? theme.colorScheme.primary
        : isDark
        ? Colors.white
        : Colors.grey.shade700;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: !isCompleted
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isCompleted ? theme.colorScheme.primary : iconColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            if (isCompleted) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Row of [HabitPill] widgets with overflow handling.
class HabitPillBar extends StatelessWidget {
  const HabitPillBar({super.key, required this.habits});

  final List<HabitPillData> habits;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: habits.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final habit = habits[index];
          return HabitPill(
            icon: habit.icon,
            label: habit.label,
            iconColor: habit.iconColor,
            isCompleted: habit.isCompleted,
            onTap: habit.onTap,
          );
        },
      ),
    );
  }
}

/// Immutable habit id + label for pill rendering.
class HabitPillData {
  const HabitPillData({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.isCompleted = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final bool isCompleted;
  final VoidCallback? onTap;
}
