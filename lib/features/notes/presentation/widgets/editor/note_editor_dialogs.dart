import 'package:flutter/material.dart';

/// Note editor dialogs and small pure helpers.
class NoteEditorDialogs {
  static Future<String?> showFindDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Find in note'),
          content: TextField(
            controller: c,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Search text'),
            onSubmitted: (v) => Navigator.of(context).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(c.text),
              child: const Text('Find'),
            ),
          ],
        );
      },
    );
  }

  static Future<bool?> showConfirmDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This will remove the note from your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static int countOccurrences(String haystack, String needle) {
    if (needle.isEmpty) return 0;
    var count = 0;
    var start = 0;
    while (true) {
      final idx = haystack.indexOf(needle, start);
      if (idx == -1) return count;
      count += 1;
      start = idx + needle.length;
      if (start >= haystack.length) return count;
    }
  }
}
