import 'package:flutter/material.dart';

/// Calendar-style heatmap of habit completion density.
class HabitHeatmap extends StatelessWidget {
  const HabitHeatmap({super.key, required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    // Mock data for the heatmap (7 rows x 13 columns approx 3 months)
    final List<int> activityLevels = List.generate(91, (index) => (index % 4));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Consistency',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Row(
              children: [
                Text(
                  'Less',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                _LegendBox(color: colorScheme.primary.withValues(alpha: 0.1)),
                const SizedBox(width: 2),
                _LegendBox(color: colorScheme.primary.withValues(alpha: 0.4)),
                const SizedBox(width: 2),
                _LegendBox(color: colorScheme.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 2),
                _LegendBox(color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'More',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Heatmap Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 13, // 13 weeks
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1.0,
          ),
          itemCount: 91,
          itemBuilder: (context, index) {
            final level = activityLevels[index];
            return Container(
              decoration: BoxDecoration(
                color: _getColorForLevel(level),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getColorForLevel(int level) {
    switch (level) {
      case 0:
        return colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
      case 1:
        return colorScheme.primary.withValues(alpha: 0.2);
      case 2:
        return colorScheme.primary.withValues(alpha: 0.5);
      case 3:
        return colorScheme.primary;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }
}

class _LegendBox extends StatelessWidget {
  const _LegendBox({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
