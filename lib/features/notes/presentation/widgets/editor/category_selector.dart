import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/bottom_sheet/nexus_bottom_sheet.dart';
import 'package:nexus/features/notes/presentation/state_management/note_controller.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';
import 'package:provider/provider.dart';

/// Dropdown of categories for the note editor toolbar.

class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key, required this.note});

  final NoteEntity note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 16, 12),
      child: Consumer<CategoryController>(
        builder: (context, catController, _) {
          final category = note.categoryId != null
              ? catController.getById(note.categoryId!)
              : null;
          final theme = Theme.of(context);

          return GestureDetector(
            onTap: () => _showCategoryPicker(context, note, catController),
            child: Row(
              children: [
                Icon(
                  Icons.label_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  category?.name ?? 'No Category',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCategoryPicker(
    BuildContext context,
    NoteEntity note,
    CategoryController categoryController,
  ) {
    showNexusBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final categories = categoryController.rootCategories;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Category',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: categories.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        leading: const Icon(Icons.block),
                        title: const Text('No Category'),
                        onTap: () {
                          context.read<NoteController>().updateCategory(
                            note,
                            null,
                          );
                          Navigator.pop(context);
                        },
                        selected: note.categoryId == null,
                      );
                    }
                    if (index == categories.length + 1) {
                      return ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('Create New Category'),
                        onTap: () {
                          Navigator.pop(context);
                          _showCreateCategoryDialog(
                            context,
                            categoryController,
                            note,
                          );
                        },
                      );
                    }
                    final category = categories[index - 1];
                    return ListTile(
                      leading: const Icon(Icons.label_outline),
                      title: Text(category.name),
                      onTap: () {
                        context.read<NoteController>().updateCategory(
                          note,
                          category.id,
                        );
                        Navigator.pop(context);
                      },
                      selected: note.categoryId == category.id,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateCategoryDialog(
    BuildContext context,
    CategoryController controller,
    NoteEntity note,
  ) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(labelText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                final cat = await controller.createCategory(name);
                if (context.mounted) {
                  context.read<NoteController>().updateCategory(note, cat.id);
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
