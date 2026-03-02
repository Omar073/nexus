import 'package:flutter/material.dart';

class ReminderSelectionBar extends StatelessWidget {
  const ReminderSelectionBar({
    super.key,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onExitSelection,
    required this.onToggleComplete,
    required this.onSnooze,
    required this.onDelete,
  });

  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onExitSelection;
  final VoidCallback onToggleComplete;
  final VoidCallback onSnooze;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Exit selection',
              icon: const Icon(Icons.close),
              onPressed: onExitSelection,
            ),
            const SizedBox(width: 8),
            Text(
              '$selectedCount selected',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Select all',
              icon: const Icon(Icons.select_all),
              onPressed: onSelectAll,
            ),
            IconButton(
              tooltip: 'Toggle complete',
              icon: const Icon(Icons.check_circle_outline),
              onPressed: onToggleComplete,
            ),
            IconButton(
              tooltip: 'Snooze 5m',
              icon: const Icon(Icons.snooze),
              onPressed: onSnooze,
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              color: theme.colorScheme.error,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
