import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/controllers/category_controller.dart';
import 'package:nexus/features/tasks/models/category.dart';

class TaskCategorySelector extends StatelessWidget {
  const TaskCategorySelector({
    super.key,
    required this.categoryController,
    required this.selectedCategoryId,
    required this.selectedSubcategoryId,
    required this.onCategoryChanged,
    required this.onSubcategoryChanged,
    required this.onCreateNewCategory,
    required this.onCreateNewSubcategory,
  });

  final CategoryController categoryController;
  final String? selectedCategoryId;
  final String? selectedSubcategoryId;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onSubcategoryChanged;
  final VoidCallback onCreateNewCategory;
  final VoidCallback onCreateNewSubcategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = categoryController.rootCategories;
    final subcategories = selectedCategoryId != null
        ? categoryController.getSubcategories(selectedCategoryId!)
        : <Category>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // Category dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedCategoryId,
              hint: const Text('Select category'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No category'),
                ),
                ...categories.map(
                  (c) => DropdownMenuItem<String?>(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  ),
                ),
                // Add new category option
                DropdownMenuItem<String?>(
                  value: '__create_new__',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Create new category',
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == '__create_new__') {
                  onCreateNewCategory();
                } else {
                  onCategoryChanged(value);
                }
              },
            ),
          ),
        ),
        // Subcategory dropdown (only if category is selected)
        if (selectedCategoryId != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selectedSubcategoryId,
                hint: const Text('Select subcategory (optional)'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No subcategory'),
                  ),
                  ...subcategories.map(
                    (c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Row(
                        children: [
                          Icon(
                            Icons.subdirectory_arrow_right,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(c.name),
                        ],
                      ),
                    ),
                  ),
                  // Add new subcategory option
                  DropdownMenuItem<String?>(
                    value: '__create_new_sub__',
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Create new subcategory',
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == '__create_new_sub__') {
                    onCreateNewSubcategory();
                  } else {
                    onSubcategoryChanged(value);
                  }
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
