import 'package:flutter/material.dart';

/// Prompts for a category or subcategory name.
Future<String?> showTaskCategoryNameDialog(
  BuildContext context, {
  required bool isSubcategory,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isSubcategory ? 'New Subcategory' : 'New Category'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: isSubcategory ? 'Subcategory name' : 'Category name',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Create'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
