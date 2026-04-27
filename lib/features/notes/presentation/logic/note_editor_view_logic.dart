import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';
import 'package:nexus/app/router/app_routes.dart';
import 'package:nexus/features/notes/domain/entities/note_entity.dart';

quill.QuillController buildNoteQuillController(NoteEntity note) {
  try {
    final decoded = jsonDecode(note.contentDeltaJson);
    final doc = quill.Document.fromJson(
      (decoded as List).cast<Map<String, dynamic>>(),
    );
    return quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  } catch (_) {
    final doc = quill.Document()..insert(0, ' ');
    return quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }
}

void showFindResultSnackBar({
  required BuildContext context,
  required String query,
  required int matches,
}) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        matches == 0
            ? 'No matches for “$query”.'
            : 'Found $matches matches for “$query”.',
      ),
      backgroundColor: matches == 0
          ? theme.colorScheme.error
          : theme.colorScheme.inverseSurface,
    ),
  );
}

void navigateToNotesAfterEditorDelete({
  required BuildContext context,
  required GlobalKey<NavigatorState> rootNavigatorKey,
}) {
  Navigator.of(context, rootNavigator: true).pop();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    GoRouter.of(ctx).go(AppRoute.notes.path);
  });
}
