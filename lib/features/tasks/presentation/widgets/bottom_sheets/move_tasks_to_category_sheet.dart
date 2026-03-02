import 'package:flutter/material.dart';
import 'package:nexus/features/categories/data/models/category.dart';

/// Bottom sheet for choosing a category when moving selected tasks.
class MoveTasksToCategorySheet {
  MoveTasksToCategorySheet._();

  static Future<String?> show(
    BuildContext context, {
    required List<Category> categories,
  }) {
    final theme = Theme.of(context);
    final nav = Navigator.of(context);

    return showModalBottomSheet<String?>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: const Text('Move to...'), dense: true),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Uncategorized'),
                onTap: () => nav.pop(null),
              ),
              const Divider(height: 0),
              ...categories.map(
                (c) => ListTile(
                  leading: Icon(Icons.folder, color: theme.colorScheme.primary),
                  title: Text(c.name),
                  onTap: () => nav.pop(c.id),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
