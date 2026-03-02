import 'package:flutter/material.dart';
import 'package:nexus/features/categories/data/models/category.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:nexus/features/categories/presentation/widgets/category_dialogs.dart';
import 'package:nexus/features/categories/presentation/widgets/category_tile.dart';

/// A category item for the drawer: root category + its subcategories.
/// Handles edit, delete, and undo snackbar for delete.
class CategoryDrawerItem extends StatelessWidget {
  const CategoryDrawerItem({
    super.key,
    required this.category,
    required this.subcategories,
    required this.taskCountByCategory,
    required this.onClearTasks,
    required this.onCategorySelected,
    required this.categoryController,
  });

  final Category category;
  final List<Category> subcategories;
  final Map<String?, int> taskCountByCategory;
  final Future<void> Function(List<String> categoryIds) onClearTasks;
  final ValueChanged<String?> onCategorySelected;
  final CategoryController categoryController;

  @override
  Widget build(BuildContext context) {
    final count = taskCountByCategory[category.id] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CategoryTile(
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
          onDelete: () => _handleDeleteCategory(context),
        ),
        ...subcategories.map((sub) {
          final subCount = taskCountByCategory[sub.id] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(left: 24),
            child: CategoryTile(
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
              onDelete: () => _handleDeleteSubcategory(context, sub),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _handleDeleteCategory(BuildContext context) async {
    final confirmed = await showCategoryDeleteDialog(
      context,
      category: category,
    );
    if (!confirmed) return;

    final toRestore = [
      Category(
        id: category.id,
        name: category.name,
        parentId: category.parentId,
      ),
      ...subcategories.map(
        (s) => Category(id: s.id, name: s.name, parentId: s.parentId),
      ),
    ];
    await categoryController.deleteCategory(
      category.id,
      onClearTasks: onClearTasks,
    );
    if (!context.mounted) return;
    _showUndoSnackBar(context, toRestore);
  }

  Future<void> _handleDeleteSubcategory(
    BuildContext context,
    Category sub,
  ) async {
    final confirmed = await showCategoryDeleteDialog(context, category: sub);
    if (!confirmed) return;

    final toRestore = [
      Category(id: sub.id, name: sub.name, parentId: sub.parentId),
    ];
    await categoryController.deleteCategory(sub.id, onClearTasks: onClearTasks);
    if (!context.mounted) return;
    _showUndoSnackBar(context, toRestore);
  }

  void _showUndoSnackBar(BuildContext context, List<Category> toRestore) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            await categoryController.restoreCategories(toRestore);
            messenger.hideCurrentSnackBar();
          },
          child: Row(
            children: [
              const Expanded(child: Text('Category deleted')),
              Text(
                'Click to undo',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
