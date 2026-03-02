import 'package:flutter/material.dart';

class TaskMoreMenu extends StatelessWidget {
  const TaskMoreMenu({super.key, required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: theme.colorScheme.onSurfaceVariant,
        size: 20,
      ),
      onSelected: (value) {
        if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}
