import 'package:flutter/material.dart';
import 'package:nexus/features/categories/data/models/category.dart';

/// A tile for displaying a category (or uncategorized) in lists.
/// Shows name, task count, and optional edit/delete menu.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.name,
    required this.count,
    required this.onTap,
    this.category,
    this.icon,
    this.isSubcategory = false,
    this.onEdit,
    this.onDelete,
  });

  final String name;
  final int count;
  final VoidCallback onTap;
  final Category? category;
  final IconData? icon;
  final bool isSubcategory;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon ??
            (isSubcategory
                ? Icons.subdirectory_arrow_right
                : Icons.folder_outlined),
        color: theme.colorScheme.primary,
        size: isSubcategory ? 18 : 22,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontSize: isSubcategory ? 14 : 15,
          fontWeight: isSubcategory ? FontWeight.w400 : FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          if (category != null) ...[
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit?.call();
                  case 'delete':
                    onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Rename'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
