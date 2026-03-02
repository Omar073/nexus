import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/core/widgets/circular_checkbox.dart';
import 'package:nexus/core/widgets/nexus_card.dart';
import 'package:nexus/features/reminders/presentation/state_management/reminder_controller.dart';
import 'package:nexus/features/reminders/domain/entities/reminder_entity.dart';
import 'package:nexus/features/reminders/presentation/widgets/reminder_editor_dialog.dart';
import 'package:provider/provider.dart';

/// A premium list tile for displaying a reminder with actions.
class ReminderTile extends StatelessWidget {
  const ReminderTile({
    super.key,
    required this.reminder,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
    this.onLongPress,
  });

  final ReminderEntity reminder;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ReminderController>();
    final done = reminder.completedAt != null;
    final theme = Theme.of(context);

    final card = NexusCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      leftBorderColor: isSelected ? theme.colorScheme.primary : null,
      child: Row(
        children: [
          // Interactive Checkbox
          CircularCheckbox(
            value: done,
            onChanged: (value) {
              if (value) {
                controller.complete(reminder);
              } else {
                controller.uncomplete(reminder);
              }
            },
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done
                        ? theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          )
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.jm().format(reminder.time),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: done
                        ? theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          )
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Menu
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            onSelected: (v) {
              switch (v) {
                case 'edit':
                  showReminderEditorDialog(context, reminder: reminder);
                case 'snooze':
                  controller.snooze(reminder);
                case 'delete':
                  controller.delete(reminder);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'snooze', child: Text('Snooze 5m')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      onTap: selectionMode ? onSelectionToggle : null,
      child: card,
    );
  }
}
