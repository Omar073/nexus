import 'package:flutter/material.dart';

/// Expandable section header for a category on the tasks tab.

class CategoryHeader extends StatelessWidget {
  const CategoryHeader({
    super.key,
    required this.title,
    required this.taskCount,
    required this.isExpanded,
    this.onAddPressed,
  });

  final String title;
  final int taskCount;
  final bool isExpanded;
  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.folder_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$taskCount',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          if (onAddPressed != null) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: onAddPressed,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Icon(
                    Icons.add,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
