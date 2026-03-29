import 'package:flutter/material.dart';
import 'package:nexus/features/categories/data/models/category.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/categories/presentation/widgets/category_drawer_item.dart';
import 'package:nexus/features/categories/presentation/widgets/category_tile.dart';
import 'package:provider/provider.dart';

/// Bottom sheet drawer showing categories for jump-to navigation.
/// [onClearTasks] is provided by the tasks feature so categories has no dependency on tasks.
class CategoryDrawer extends StatelessWidget {
  const CategoryDrawer({
    super.key,
    required this.onCategorySelected,
    required this.taskCountByCategory,
    required this.sortedCategories,
    required this.onClearTasks,
    this.scrollController,
  });

  final ValueChanged<String?> onCategorySelected;
  final Map<String?, int> taskCountByCategory;
  final List<Category> sortedCategories;
  final Future<void> Function(List<String> categoryIds) onClearTasks;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryController = context.watch<CategoryController>();
    final categories = sortedCategories;
    bool gestureStartedAtTop = false;

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Column(
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
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // Only allow overscroll-to-dismiss if the gesture STARTED at the top.
                // This prevents \"scroll up from bottom → reach top → dismiss\" in the same gesture.
                if (notification is ScrollStartNotification) {
                  gestureStartedAtTop = notification.metrics.pixels <= 0;
                }
                if (notification is ScrollEndNotification) {
                  gestureStartedAtTop = false;
                }
                if (notification is OverscrollNotification &&
                    gestureStartedAtTop &&
                    notification.metrics.pixels <= 0 &&
                    notification.overscroll < 0) {
                  Navigator.of(context).maybePop();
                }
                return false;
              },
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  CategoryTile(
                    name: 'Uncategorized',
                    count: taskCountByCategory[null] ?? 0,
                    icon: Icons.inbox_outlined,
                    onTap: () {
                      Navigator.pop(context);
                      onCategorySelected(null);
                    },
                  ),
                  ...categories.map((category) {
                    final subcategories = categoryController.getSubcategories(
                      category.id,
                    );
                    return CategoryDrawerItem(
                      category: category,
                      subcategories: subcategories,
                      taskCountByCategory: taskCountByCategory,
                      onClearTasks: onClearTasks,
                      onCategorySelected: onCategorySelected,
                      categoryController: categoryController,
                    );
                  }),
                ],
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
