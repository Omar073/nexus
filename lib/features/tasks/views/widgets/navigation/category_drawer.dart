import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/category_controller.dart';
import 'package:nexus/features/tasks/controllers/task_controller.dart';
import 'package:nexus/features/tasks/models/category.dart';
import 'package:nexus/features/tasks/views/widgets/dialogs/category_dialogs.dart';
import 'package:provider/provider.dart';

/// Bottom sheet drawer showing categories for jump-to navigation.
class CategoryDrawer extends StatelessWidget {
  const CategoryDrawer({
    super.key,
    required this.onCategorySelected,
    required this.taskCountByCategory,
  });

  final ValueChanged<String?> onCategorySelected;
  final Map<String?, int> taskCountByCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryController = context.watch<CategoryController>();
    final taskController = context.read<TaskController>();
    final categories = categoryController.rootCategories;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.format_list_bulleted,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Jump to Category',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Category list
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Uncategorized option
                _CategoryTile(
                  name: 'Uncategorized',
                  count: taskCountByCategory[null] ?? 0,
                  icon: Icons.inbox_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    onCategorySelected(null);
                  },
                ),
                // Root categories with sub-categories
                ...categories.map((category) {
                  final subcategories = categoryController.getSubcategories(
                    category.id,
                  );
                  return _buildCategoryItem(
                    context,
                    category: category,
                    subcategories: subcategories,
                    categoryController: categoryController,
                    taskController: taskController,
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context, {
    required Category category,
    required List<Category> subcategories,
    required CategoryController categoryController,
    required TaskController taskController,
  }) {
    final count = taskCountByCategory[category.id] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryTile(
          name: category.name,
          count: count,
          category: category,
          onTap: () {
            Navigator.pop(context);
            onCategorySelected(category.id);
          },
          onEdit: () => showCategoryEditDialog(
            context,
            category: category,
            controller: categoryController,
          ),
          onDelete: () async {
            final confirmed = await showCategoryDeleteDialog(
              context,
              category: category,
            );
            if (confirmed) {
              await categoryController.deleteCategory(
                category.id,
                onClearTasks: taskController.clearCategoryOnTasks,
              );
            }
          },
        ),
        // Sub-categories (indented)
        ...subcategories.map((sub) {
          final subCount = taskCountByCategory[sub.id] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(left: 24),
            child: _CategoryTile(
              name: sub.name,
              count: subCount,
              category: sub,
              isSubcategory: true,
              onTap: () {
                Navigator.pop(context);
                onCategorySelected(sub.id);
              },
              onEdit: () => showCategoryEditDialog(
                context,
                category: sub,
                controller: categoryController,
              ),
              onDelete: () async {
                final confirmed = await showCategoryDeleteDialog(
                  context,
                  category: sub,
                );
                if (confirmed) {
                  await categoryController.deleteCategory(
                    sub.id,
                    onClearTasks: taskController.clearCategoryOnTasks,
                  );
                }
              },
            ),
          );
        }),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
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
          // Menu button (only for editable categories)
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
