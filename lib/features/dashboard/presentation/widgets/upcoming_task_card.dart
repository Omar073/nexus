import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/circular_checkbox.dart';
import 'package:nexus/core/widgets/nexus_card.dart';

/// Task card for upcoming tasks list following Nexus design.
/// Shows circular checkbox, title, due time, and optional priority indicator.
class UpcomingTaskCard extends StatelessWidget {
  const UpcomingTaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.onToggle,
    this.isHighPriority = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isCompleted;
  final ValueChanged<bool> onToggle;
  final bool isHighPriority;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NexusCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      onTap: onTap,
      child: Row(
        children: [
          CircularCheckbox(value: isCompleted, onChanged: onToggle),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isHighPriority) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
