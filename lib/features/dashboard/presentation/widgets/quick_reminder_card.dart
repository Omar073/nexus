import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/nexus_card.dart';
import 'package:nexus/features/dashboard/presentation/models/quick_reminder_data.dart';

/// Quick reminder card following Nexus design.
/// Shows a left-colored border with time, title, and subtitle.
class QuickReminderCard extends StatelessWidget {
  const QuickReminderCard({
    super.key,
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.onTap,
  });

  final String timeLabel;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NexusCard(
      leftBorderColor: accentColor,
      padding: const EdgeInsets.all(12),
      borderRadius: 12,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accentColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Grid of [QuickReminderCard] on the dashboard.
class QuickRemindersGrid extends StatelessWidget {
  const QuickRemindersGrid({super.key, required this.reminders});

  final List<QuickReminderData> reminders;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: reminders
          .map(
            (r) => QuickReminderCard(
              timeLabel: r.timeLabel,
              title: r.title,
              subtitle: r.subtitle,
              accentColor: r.accentColor,
              onTap: r.onTap,
            ),
          )
          .toList(),
    );
  }
}
