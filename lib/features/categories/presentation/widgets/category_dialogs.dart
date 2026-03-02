import 'package:flutter/material.dart';
import 'package:nexus/features/categories/data/models/category.dart';
import 'package:nexus/features/categories/presentation/state_management/category_controller.dart';

/// Dialog to edit a category's name.
Future<void> showCategoryEditDialog(
  BuildContext context, {
  required Category category,
  required CategoryController controller,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) =>
        _CategoryEditDialog(category: category, controller: controller),
  );
}

class _CategoryEditDialog extends StatefulWidget {
  const _CategoryEditDialog({required this.category, required this.controller});

  final Category category;
  final CategoryController controller;

  @override
  State<_CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<_CategoryEditDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.category.name);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Edit Category'),
      content: TextField(
        controller: _textController,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Category Name',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: () {
            final newName = _textController.text.trim();
            if (newName.isNotEmpty && newName != widget.category.name) {
              widget.controller.updateCategory(widget.category, newName);
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Dialog to confirm category deletion.
Future<bool> showCategoryDeleteDialog(
  BuildContext context, {
  required Category category,
}) async {
  final theme = Theme.of(context);

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Category'),
      content: Text(
        'Are you sure you want to delete "${category.name}"?\n\n'
        'Tasks in this category will become uncategorized.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  return result ?? false;
}
